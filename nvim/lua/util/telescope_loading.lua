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
