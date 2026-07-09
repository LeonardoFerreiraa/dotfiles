-- Shared Telescope "loading" placeholder finder, used by pickers that open
-- immediately and refresh with real results once an async LSP request
-- completes (see lsp_extras.lua and find_method/engine.lua). Keeping this in
-- one place ensures every such picker shows the same feedback.
local M = {}

M.TEXT = 'Buscando, aguarde…'

function M.finder()
  local finders = require('telescope.finders')
  return finders.new_table({
    results = { M.TEXT },
    entry_maker = function(line)
      return { value = line, display = line, ordinal = line }
    end,
  })
end

return M
