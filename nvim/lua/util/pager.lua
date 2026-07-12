local M = {}

function M.is_pager_argv(argv)
  for _, arg in ipairs(argv) do
    if arg:find('kitty_pager', 1, true) then
      return true
    end
  end
  return false
end

return M
