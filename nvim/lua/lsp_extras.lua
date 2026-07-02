-- Extra LSP pickers built on top of Telescope.
--
-- Both pickers here open the Telescope window immediately with a "loading"
-- placeholder entry, then refresh it with the real results once the LSP
-- responds. This gives instant feedback that the keymap was triggered,
-- instead of nothing happening for a second or two while the request is
-- in flight (noticeable with slower servers like jdtls).
local M = {}

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local LOADING_TEXT = 'Buscando, aguarde…'

local function loading_finder()
  return finders.new_table({
    results = { LOADING_TEXT },
    entry_maker = function(line)
      return { value = line, display = line, ordinal = line }
    end,
  })
end

-- Opens a Telescope picker right away with a loading placeholder, then calls
-- `request(on_result)` to fetch the real data asynchronously. `on_result`
-- must be called with either a list of quickfix-style items, or nil/empty
-- when there's nothing to show.
local function open_async_picker(prompt_title, request)
  local picker = pickers.new({}, {
    prompt_title = prompt_title,
    finder = loading_finder(),
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

-- Combines "go to definition" and "go to declaration" into a single
-- deduplicated picker. Most languages (Java included) don't have a
-- meaningful distinction between the two, so it's more useful to see both
-- merged than to have two separate, mostly-overlapping pickers.
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
      -- dedupe by uri + range, since definition and declaration usually
      -- point to the exact same location
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

-- Same as telescope.builtin.lsp_references, but opens the picker immediately
-- with a loading placeholder instead of waiting for the response first.
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

-- Same as vim.lsp.buf.code_action(), but shows the choices in a Telescope
-- picker (with the same instant-loading UX) instead of vim.ui.select's
-- default menu. Reuses the real vim.lsp.buf.code_action() implementation
-- (correct per-diagnostic context, multi-client support, codeAction/resolve,
-- applying edits/commands) by temporarily intercepting vim.ui.select.
function M.code_actions()
  local picker = pickers.new({}, {
    prompt_title = 'Code Actions',
    finder = loading_finder(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.value and M._on_choice then
          M._on_choice(entry.value)
        end
      end)
      return true
    end,
  })
  picker:find()

  local original_ui_select = vim.ui.select
  local original_notify = vim.notify
  local finished = false

  local function restore()
    vim.ui.select = original_ui_select
    vim.notify = original_notify
  end

  -- vim.lsp.buf.code_action() calls vim.notify('No code actions available', ...)
  -- (or an "unsupported method" warning) instead of vim.ui.select when there's
  -- nothing to show; catch that to close the loading picker instead of
  -- leaving it stuck on the placeholder.
  vim.notify = function(msg, level, notify_opts)
    if not finished then
      finished = true
      restore()
      pcall(actions.close, picker.prompt_bufnr)
    end
    return original_notify(msg, level, notify_opts)
  end

  vim.ui.select = function(items, select_opts, on_choice)
    finished = true
    restore()

    M._on_choice = on_choice

    local entries = {}
    for i, item in ipairs(items) do
      entries[i] = {
        value = item,
        display = select_opts.format_item and select_opts.format_item(item) or tostring(item),
      }
    end

    picker:refresh(
      finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return { value = entry.value, display = entry.display, ordinal = entry.display }
        end,
      }),
      { reset_prompt = true }
    )
  end

  vim.lsp.buf.code_action()
end

return M
