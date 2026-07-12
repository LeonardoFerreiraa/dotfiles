local M = {}

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local loading = require('util.telescope_loading')

local function open_async_picker(prompt_title, request)
  local picker = pickers.new({}, {
    prompt_title = prompt_title,
    finder = loading.finder(),
    sorter = conf.generic_sorter({}),
    previewer = conf.qflist_previewer({}),
  })
  picker:find()

  request(function(items, offset_encoding)
    if not items or #items == 0 then
      pcall(actions.close, picker.prompt_bufnr)
      vim.notify('Nenhum resultado encontrado.', vim.log.levels.INFO)
      return
    end

    if #items == 1 then
      pcall(actions.close, picker.prompt_bufnr)
      vim.lsp.util.show_document(items[1].user_data, offset_encoding, { reuse_win = true, focus = true })
      return
    end

    picker:refresh(
      finders.new_table({
        results = items,
        entry_maker = make_entry.gen_from_quickfix({}),
      }),
      { reset_prompt = true }
    )
  end)
end

function M.definitions_and_declarations()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, 'utf-16')

  local collected = {}
  local pending = 0

  local function request(method)
    pending = pending + 1
    vim.lsp.buf_request(bufnr, method, params, function(err, result, ctx)
      if not err and result then
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local offset_encoding = client and client.offset_encoding or 'utf-16'
        local flattened = vim.islist(result) and result or { result }
        for _, loc in ipairs(flattened) do
          table.insert(collected, { loc = loc, offset_encoding = offset_encoding })
        end
      end
      pending = pending - 1
      if pending == 0 then
        M._on_definitions_done(collected)
      end
    end)
  end

  open_async_picker('Definitions & Declarations', function(on_result)
    M._on_definitions_done = function(results)
      local seen = {}
      local unique = {}
      local offset_encoding
      for _, entry in ipairs(results) do
        local uri = entry.loc.uri or entry.loc.targetUri
        local range = entry.loc.range or entry.loc.targetRange
        local key = uri .. ':' .. vim.inspect(range)
        if not seen[key] then
          seen[key] = true
          table.insert(unique, entry.loc)
          offset_encoding = offset_encoding or entry.offset_encoding
        end
      end

      local items = vim.lsp.util.locations_to_items(unique, offset_encoding)
      on_result(items, offset_encoding)
    end

    request('textDocument/definition')
    request('textDocument/declaration')
  end)
end

function M.references()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, 'utf-16')
  params.context = { includeDeclaration = true }

  open_async_picker('LSP References', function(on_result)
    vim.lsp.buf_request(bufnr, 'textDocument/references', params, function(err, result, ctx)
      if err then
        vim.notify('Erro ao buscar referências: ' .. err.message, vim.log.levels.ERROR)
        on_result(nil)
        return
      end
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local offset_encoding = client and client.offset_encoding or 'utf-16'
      local items = vim.lsp.util.locations_to_items(result or {}, offset_encoding)
      on_result(items, offset_encoding)
    end)
  end)
end

function M.code_actions()
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()
  local lnum = vim.api.nvim_win_get_cursor(winnr)[1] - 1

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeAction' })
  local can_format = #vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/formatting' }) > 0
  local can_rename = #vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/rename' }) > 0
  if #clients == 0 and not can_format and not can_rename then
    vim.notify('Nenhum servidor LSP com suporte a code actions neste buffer.', vim.log.levels.WARN)
    return
  end

  local diagnostics = vim.tbl_map(function(d)
    return d.user_data and d.user_data.lsp or d
  end, vim.diagnostic.get(bufnr, { lnum = lnum }))

  local function params_fn(client)
    local range_params = vim.lsp.util.make_range_params(winnr, client.offset_encoding)
    range_params.context = {
      diagnostics = diagnostics,
      triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
    }
    return range_params
  end

  local function apply_action(action, client, ctx)
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    local a_cmd = action.command
    if a_cmd then
      local command = type(a_cmd) == 'table' and a_cmd or action
      client:exec_cmd(command, ctx)
    end
  end

  local function on_choice(item)
    if item.format then
      vim.lsp.buf.format({ bufnr = bufnr, async = true })
      return
    end

    if item.rename then
      vim.lsp.buf.rename()
      return
    end

    local client = vim.lsp.get_client_by_id(item.ctx.client_id)
    if not client then
      return
    end
    local action = item.action

    if type(action.title) == 'string' and type(action.command) == 'string' then
      apply_action(action, client, item.ctx)
      return
    end

    if action.disabled then
      vim.notify(action.disabled.reason, vim.log.levels.ERROR)
      return
    end

    if not (action.edit and action.command) and client:supports_method('codeAction/resolve') then
      client:request('codeAction/resolve', action, function(err, resolved_action)
        if err then
          if action.edit or action.command then
            apply_action(action, client, item.ctx)
          else
            vim.notify(err.code .. ': ' .. err.message, vim.log.levels.ERROR)
          end
        else
          apply_action(resolved_action, client, item.ctx)
        end
      end, item.ctx.bufnr)
    else
      apply_action(action, client, item.ctx)
    end
  end

  local picker = pickers.new({}, {
    prompt_title = 'Code Actions',
    finder = loading.finder(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.value then
          on_choice(entry.value)
        end
      end)
      return true
    end,
  })
  picker:find()

  local function finish(action_items)
    local items = {}
    if can_rename then
      table.insert(items, { value = { rename = true }, display = 'Rename Symbol' })
    end
    if can_format then
      table.insert(items, { value = { format = true }, display = 'Format Document' })
    end
    vim.list_extend(items, action_items)

    if #items == 0 then
      pcall(actions.close, picker.prompt_bufnr)
      vim.notify('Nenhuma code action disponível.', vim.log.levels.INFO)
      return
    end

    picker:refresh(
      finders.new_table({
        results = items,
        entry_maker = function(entry)
          return { value = entry.value, display = entry.display, ordinal = entry.display }
        end,
      }),
      { reset_prompt = true }
    )
  end

  if #clients == 0 then
    finish({})
    return
  end

  vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', params_fn, function(results)
    local action_items = {}
    for client_id, result in pairs(results) do
      local client = vim.lsp.get_client_by_id(client_id)
      for _, action in ipairs(result.result or {}) do
        local title = action.title:gsub('\r\n', '\\r\\n'):gsub('\n', '\\n')
        if #clients > 1 and client then
          title = title .. ' [' .. client.name .. ']'
        end
        table.insert(action_items, {
          value = { action = action, ctx = result.context },
          display = title,
        })
      end
    end

    finish(action_items)
  end)
end

return M
