local M = {}

local KIND_CLASS = 5
local KIND_METHOD = 6
local KIND_ENUM = 10
local KIND_INTERFACE = 11
local KIND_CONSTRUCTOR = 9

local CLASS_LIKE = { [KIND_CLASS] = true, [KIND_ENUM] = true, [KIND_INTERFACE] = true }
local METHOD_LIKE = { [KIND_METHOD] = true, [KIND_CONSTRUCTOR] = true }

local function get_client(bufnr, provider)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if not provider.client_name or c.name == provider.client_name then
      return c
    end
  end
  return nil
end

local function query_classes(bufnr, prompt)
  if not prompt or prompt == '' then
    return {}
  end
  local responses = vim.lsp.buf_request_sync(bufnr, 'workspace/symbol', { query = prompt }, 1500)
  local out = {}
  if not responses then
    return out
  end
  for _, resp in pairs(responses) do
    for _, sym in ipairs(resp.result or {}) do
      if CLASS_LIKE[sym.kind] and sym.location and sym.location.uri then
        local container = sym.containerName
        local fqn = (container and container ~= '') and (container .. '.' .. sym.name) or sym.name
        table.insert(out, {
          fqn = fqn,
          name = sym.name,
          kind = sym.kind,
          uri = sym.location.uri,
          range = sym.location.range,
        })
      end
    end
  end
  return out
end

local function load_class_buffer(uri)
  local class_bufnr
  if vim.startswith(uri, 'file://') then
    class_bufnr = vim.uri_to_bufnr(uri)
  else
    class_bufnr = vim.fn.bufadd(uri)
  end
  vim.fn.bufload(class_bufnr)

  local attached = vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = class_bufnr }) > 0
  end)
  if not attached then
    return nil
  end
  return class_bufnr
end

local function strip_generics(name)
  return (name:gsub('%s*<.*', ''))
end

local function find_class_symbol(symbols, name)
  local target = strip_generics(name)
  for _, sym in ipairs(symbols or {}) do
    if CLASS_LIKE[sym.kind] and strip_generics(sym.name) == target then
      return sym
    end
    local found = find_class_symbol(sym.children, name)
    if found then
      return found
    end
  end
  return nil
end

local function hover_to_markdown(contents)
  if not contents then
    return nil
  end
  if type(contents) == 'string' then
    return contents
  end
  if contents.value then
    return contents.value
  end
  local parts = {}
  for _, c in ipairs(contents) do
    table.insert(parts, type(c) == 'string' and c or (c.value or ''))
  end
  local joined = table.concat(parts, '\n')
  return joined ~= '' and joined or nil
end

local function extract_signature(markdown, provider, fqn)
  local sig = markdown:match('```%w*%s*\n(.-)\n```')
  if not sig then
    return nil
  end
  return provider.clean_signature(sig, fqn)
end

local function open_methods_picker(fqn, offset_encoding)
  local pickers = require('telescope.pickers')
  local conf = require('telescope.config').values
  local previewers = require('telescope.previewers')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local loading = require('util.telescope_loading')

  local picker = pickers.new({}, {
    prompt_title = fqn,
    finder = loading.finder(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and type(entry.value) == 'table' and entry.value.uri then
          vim.lsp.util.show_document(
            { uri = entry.value.uri, range = entry.value.range },
            offset_encoding,
            { reuse_win = true, focus = true }
          )
        end
      end)
      return true
    end,
    previewer = previewers.new_buffer_previewer({
      title = 'Doc',
      define_preview = function(self, entry)
        local md = type(entry.value) == 'table' and (entry.value.doc or entry.value.sig) or entry.value
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(md, '\n', { plain = true }))
        vim.bo[self.state.bufnr].filetype = 'markdown'
        vim.wo[self.state.winid].wrap = true
        vim.wo[self.state.winid].conceallevel = 2
        pcall(vim.treesitter.start, self.state.bufnr, 'markdown')
      end,
    }),
  })
  picker:find()
  return picker
end

local function fetch_and_show(provider, class_bufnr, uri, item, methods, picker)
  local finders = require('telescope.finders')
  local entries = {}
  local pending = #methods

  for i, method in ipairs(methods) do
    local params = {
      textDocument = { uri = uri },
      position = method.selectionRange.start,
    }
    vim.lsp.buf_request(class_bufnr, 'textDocument/hover', params, function(_, result)
      local markdown = result and hover_to_markdown(result.contents)
      local sig = (markdown and extract_signature(markdown, provider, item.fqn)) or method.name
      entries[i] = {
        sig = sig,
        doc = markdown or ('# ' .. method.name),
        uri = uri,
        range = method.selectionRange,
      }
      pending = pending - 1
      if pending == 0 then
        local ordered = {}
        for j = 1, #methods do
          if entries[j] then
            table.insert(ordered, entries[j])
          end
        end
        picker:refresh(
          finders.new_table({
            results = ordered,
            entry_maker = function(e)
              return { value = e, display = e.sig, ordinal = e.sig }
            end,
          }),
          { reset_prompt = true }
        )
      end
    end)
  end
end

local function show_methods(provider, item)
  local class_bufnr = load_class_buffer(item.uri)
  if not class_bufnr then
    vim.notify('LSP não anexou ao carregar ' .. item.fqn, vim.log.levels.ERROR)
    return
  end
  local client = get_client(class_bufnr, provider)
  local offset_encoding = client and client.offset_encoding or 'utf-16'
  local picker = open_methods_picker(item.fqn, offset_encoding)

  local params = { textDocument = { uri = item.uri } }
  vim.lsp.buf_request(class_bufnr, 'textDocument/documentSymbol', params, function(err, result)
    if err or not result then
      pcall(require('telescope.actions').close, picker.prompt_bufnr)
      vim.notify('Falha ao obter símbolos de ' .. item.fqn, vim.log.levels.ERROR)
      return
    end
    local class_sym = find_class_symbol(result, item.name)
    if not class_sym then
      pcall(require('telescope.actions').close, picker.prompt_bufnr)
      vim.notify('Classe ' .. item.name .. ' não encontrada nos símbolos.', vim.log.levels.ERROR)
      return
    end
    local methods = {}
    for _, child in ipairs(class_sym.children or {}) do
      if METHOD_LIKE[child.kind] and child.selectionRange and child.range and provider.is_public(class_bufnr, child, class_sym) then
        table.insert(methods, child)
      end
    end
    if #methods == 0 then
      pcall(require('telescope.actions').close, picker.prompt_bufnr)
      vim.notify('Nenhum método público encontrado em ' .. item.fqn, vim.log.levels.INFO)
      return
    end
    fetch_and_show(provider, class_bufnr, item.uri, item, methods, picker)
  end)
end

function M.run(provider)
  local bufnr = vim.api.nvim_get_current_buf()
  if not get_client(bufnr, provider) then
    vim.notify('Nenhum LSP (' .. (provider.client_name or 'qualquer') .. ') anexado a este buffer.', vim.log.levels.WARN)
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers
    .new({}, {
      prompt_title = 'Classes (' .. provider.name .. ') — digite para buscar',
      finder = finders.new_dynamic({
        fn = function(prompt)
          return query_classes(bufnr, prompt)
        end,
        entry_maker = function(class_item)
          return { value = class_item, display = class_item.fqn, ordinal = class_item.fqn }
        end,
      }),
      sorter = conf.generic_sorter({}),
      debounce = 150,
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.value then
            vim.schedule(function()
              show_methods(provider, entry.value)
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
