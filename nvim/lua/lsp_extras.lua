-- Combines "go to definition" and "go to declaration" LSP requests into a
-- single deduplicated Telescope picker. Most languages (Java included) don't
-- have a meaningful distinction between the two, so it's more useful to see
-- both results merged than to have two separate, mostly-overlapping pickers.
local M = {}

function M.definitions_and_declarations()
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0, 'utf-16')

  local collected = {}
  local pending = 0

  local function on_done()
    if #collected == 0 then
      vim.notify('Nenhuma definição/declaração encontrada.', vim.log.levels.INFO)
      return
    end

    -- dedupe by uri + range, since definition and declaration usually point
    -- to the exact same location
    local seen = {}
    local unique = {}
    local offset_encoding
    for _, entry in ipairs(collected) do
      local uri = entry.loc.uri or entry.loc.targetUri
      local range = entry.loc.range or entry.loc.targetRange
      local key = uri .. ':' .. vim.inspect(range)
      if not seen[key] then
        seen[key] = true
        table.insert(unique, entry.loc)
        offset_encoding = offset_encoding or entry.offset_encoding
      end
    end

    if #unique == 1 then
      vim.lsp.util.jump_to_location(unique[1], offset_encoding)
      return
    end

    local items = vim.lsp.util.locations_to_items(unique, offset_encoding)
    pickers
      .new({}, {
        prompt_title = 'Definitions & Declarations',
        finder = finders.new_table({
          results = items,
          entry_maker = make_entry.gen_from_quickfix({}),
        }),
        previewer = conf.qflist_previewer({}),
        sorter = conf.generic_sorter({}),
      })
      :find()
  end

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
        on_done()
      end
    end)
  end

  request('textDocument/definition')
  request('textDocument/declaration')
end

return M
