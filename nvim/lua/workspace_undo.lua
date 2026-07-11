-- Neovim's undo is per-buffer, so a multi-file LSP workspace edit (rename,
-- some code actions/refactors) can't be undone with a single `u` — that
-- only reverts the buffer you're standing in, leaving every other touched
-- file changed. This wraps vim.lsp.util.apply_workspace_edit to record
-- which buffers a given edit touched and their undo-tree position before
-- and after, so the whole edit can be rolled back across files at once.
local M = {}

local history = {}
local MAX_HISTORY = 20

local function bufs_from_workspace_edit(workspace_edit)
  local seen, bufs = {}, {}
  local function add(uri)
    local buf = vim.uri_to_bufnr(uri)
    if not seen[buf] then
      seen[buf] = true
      table.insert(bufs, buf)
    end
  end

  if workspace_edit.changes then
    for uri, _ in pairs(workspace_edit.changes) do
      add(uri)
    end
  end
  if workspace_edit.documentChanges then
    for _, change in ipairs(workspace_edit.documentChanges) do
      if change.textDocument then
        add(change.textDocument.uri)
      end
    end
  end
  return bufs
end

function M.setup()
  local orig_apply_workspace_edit = vim.lsp.util.apply_workspace_edit
  vim.lsp.util.apply_workspace_edit = function(workspace_edit, offset_encoding)
    local bufs = bufs_from_workspace_edit(workspace_edit)
    for _, buf in ipairs(bufs) do
      vim.fn.bufload(buf)
    end

    local before = {}
    for _, buf in ipairs(bufs) do
      before[buf] = vim.fn.undotree(buf).seq_cur
    end

    local result = orig_apply_workspace_edit(workspace_edit, offset_encoding)

    local record = {}
    for _, buf in ipairs(bufs) do
      local after = vim.fn.undotree(buf).seq_cur
      if after ~= before[buf] then
        table.insert(record, { buf = buf, before = before[buf], after = after })
      end
    end
    if #record > 0 then
      table.insert(history, record)
      if #history > MAX_HISTORY then
        table.remove(history, 1)
      end
    end

    return result
  end
end

-- Undoes the most recent workspace edit across every buffer it touched. If a
-- buffer was edited again after the workspace edit landed, that buffer is
-- skipped (its undo-tree position no longer matches) and reported, rather
-- than clobbering unrelated later edits.
function M.undo_last()
  local record = table.remove(history)
  if not record then
    vim.notify('Nenhum workspace edit para desfazer.', vim.log.levels.INFO)
    return
  end

  local undone, skipped = 0, {}
  for _, entry in ipairs(record) do
    if vim.api.nvim_buf_is_loaded(entry.buf) then
      local cur = vim.fn.undotree(entry.buf).seq_cur
      if cur == entry.after then
        vim.api.nvim_buf_call(entry.buf, function()
          vim.cmd('silent! undo ' .. entry.before)
        end)
        undone = undone + 1
      else
        table.insert(skipped, vim.api.nvim_buf_get_name(entry.buf))
      end
    end
  end

  if #skipped > 0 then
    vim.notify(
      'Desfeito em ' .. undone .. ' arquivo(s). Pulado (editado depois): ' .. table.concat(skipped, ', '),
      vim.log.levels.WARN
    )
  else
    vim.notify('Workspace edit desfeito em ' .. undone .. ' arquivo(s).', vim.log.levels.INFO)
  end
end

-- Drop-in replacement for the `u` keymap. If the cursor's buffer sits right
-- at the boundary the last recorded workspace edit left it in (nothing else
-- was typed since), `u` undoes that edit across every file it touched;
-- otherwise it's a plain single-buffer undo, same as always.
function M.smart_undo()
  if vim.v.count > 1 then
    vim.cmd('normal! ' .. vim.v.count .. 'u')
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local top = history[#history]
  if top then
    for _, entry in ipairs(top) do
      if entry.buf == buf and vim.fn.undotree(buf).seq_cur == entry.after then
        M.undo_last()
        return
      end
    end
  end

  vim.cmd('undo')
end

return M
