-- File create/rename/delete actions for the command palette, including
-- jdtls-aware handling for .java files (package skeleton on create,
-- textDocument/rename on rename).

-- Version-tolerant client:supports_method (method form on 0.11+, function form
-- on older nvim).
local function supports(client, method)
  local ok, r = pcall(function()
    return client:supports_method(method)
  end)
  if ok then
    return r
  end
  ok, r = pcall(function()
    return client.supports_method(method)
  end)
  return ok and r or false
end

-- Directory to create/act in: the current file's dir when we're on a real file
-- buffer, otherwise the cwd (e.g. when invoked from the nvim-tree float).
local function target_dir()
  local cur = vim.api.nvim_buf_get_name(0)
  if cur ~= '' and vim.bo.buftype == '' and vim.fn.filereadable(cur) == 1 then
    return vim.fn.fnamemodify(cur, ':h')
  end
  return vim.fn.getcwd()
end

-- Derives the Java package from a directory by locating the source root
-- (src/main/java or src/test/java) and dotting the remainder. Returns nil for
-- the default package or when no source root is found.
local function java_package_from_dir(dir)
  local d = dir .. '/'
  for _, root in ipairs({ '/src/main/java/', '/src/test/java/' }) do
    local idx = d:find(root, 1, true)
    if idx then
      local rest = d:sub(idx + #root):gsub('/$', '')
      if rest == '' then
        return nil
      end
      return (rest:gsub('/', '.'))
    end
  end
  return nil
end

-- Builds the initial contents of a new .java file: package declaration (from
-- the path) + a public type stub. jdtls doesn't create files, so this mirrors
-- what the vscode-java "new file template" does on the client side.
local function java_skeleton(path)
  local name = vim.fn.fnamemodify(path, ':t:r')
  local pkg = java_package_from_dir(vim.fn.fnamemodify(path, ':h'))
  local lines = {}
  if pkg then
    table.insert(lines, 'package ' .. pkg .. ';')
    table.insert(lines, '')
  end
  table.insert(lines, 'public class ' .. name .. ' {')
  table.insert(lines, '')
  table.insert(lines, '}')
  return lines
end

-- Locates the position of a top-level type's name in a buffer via
-- documentSymbol, so we can drive textDocument/rename at the class name.
-- Prefers the type matching `type_name` (the filename), falls back to the first
-- class/interface/enum/record.
local function java_type_position(bufnr, type_name)
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local res = vim.lsp.buf_request_sync(bufnr, 'textDocument/documentSymbol', params, 2000)
  if not res then
    return nil
  end
  local first_type
  for _, r in pairs(res) do
    for _, s in ipairs(r.result or {}) do
      local sel = s.selectionRange or (s.location and s.location.range)
      if sel then
        if s.name == type_name then
          return sel.start
        end
        -- SymbolKind: Class=5, Enum=10, Interface=11, Struct/record=23
        if not first_type and (s.kind == 5 or s.kind == 10 or s.kind == 11 or s.kind == 23) then
          first_type = sel.start
        end
      end
    end
  end
  return first_type
end

local M = {}

function M.create_file()
  local dir = target_dir()
  vim.ui.input({ prompt = 'New file name: ' }, function(name)
    if not name or name == '' then
      return
    end
    local path = dir .. '/' .. name
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    -- seed a Java skeleton into the (empty) new buffer; other filetypes stay
    -- blank. jdtls indexes it via its file watcher once written.
    local empty = vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ''
    if name:match('%.java$') and empty then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, java_skeleton(path))
    end
    vim.cmd('write')
  end)
end

function M.rename_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local old = vim.api.nvim_buf_get_name(bufnr)
  if old == '' then
    vim.notify('No file open to rename', vim.log.levels.WARN)
    return
  end
  local dir = vim.fn.fnamemodify(old, ':h')
  local old_name = vim.fn.fnamemodify(old, ':t')
  vim.ui.input({ prompt = 'Rename to: ', default = old_name }, function(name)
    if not name or name == '' or name == old_name then
      return
    end
    -- Java + jdtls: drive textDocument/rename on the primary type. jdtls does
    -- the heavy lifting (rename class, update every reference, and emit a
    -- RenameFile so the .java file itself is moved). vim.lsp.buf.rename applies
    -- the whole WorkspaceEdit, RenameFile included.
    if vim.bo[bufnr].filetype == 'java' then
      local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'jdtls' })[1]
      if client and supports(client, 'textDocument/rename') then
        local pos = java_type_position(bufnr, vim.fn.fnamemodify(old, ':t:r'))
        if pos then
          vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.character })
          vim.lsp.buf.rename(vim.fn.fnamemodify(name, ':t:r'))
          return
        end
        vim.notify('jdtls: could not locate the type to rename; falling back to fs rename', vim.log.levels.WARN)
      end
    end
    -- Fallback: plain filesystem rename (non-java, or jdtls not attached yet).
    local new = dir .. '/' .. name
    if not os.rename(old, new) then
      vim.notify('Rename failed', vim.log.levels.ERROR)
      return
    end
    local old_buf = vim.api.nvim_get_current_buf()
    vim.cmd('edit ' .. vim.fn.fnameescape(new))
    vim.api.nvim_buf_delete(old_buf, { force = true })
  end)
end

function M.delete_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    vim.notify('No file open to delete', vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = 'Delete ' .. vim.fn.fnamemodify(path, ':t') .. '? (y/N): ' }, function(answer)
    if answer ~= 'y' and answer ~= 'Y' then
      return
    end
    -- Plain fs delete; jdtls has no willDeleteFiles but notices the removal via
    -- its file watcher (didChangeWatchedFiles).
    if vim.fn.delete(path) ~= 0 then
      vim.notify('Delete failed', vim.log.levels.ERROR)
      return
    end
    vim.api.nvim_buf_delete(0, { force = true })
  end)
end

return M
