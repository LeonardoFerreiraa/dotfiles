local M = {}

local function providers_by_filetype()
  local map = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file('lua/features/find_method/providers/*.lua', true)) do
    local name = vim.fn.fnamemodify(path, ':t:r')
    local ok, provider = pcall(require, 'features.find_method.providers.' .. name)
    if ok then
      for _, ft in ipairs(provider.filetypes or {}) do
        map[ft] = provider
      end
    end
  end
  return map
end

M._providers_by_filetype = providers_by_filetype

function M.open()
  local ft = vim.bo.filetype
  local provider = providers_by_filetype()[ft]
  if not provider then
    vim.notify('find_method: sem provider para o filetype "' .. ft .. '"', vim.log.levels.WARN)
    return
  end
  require('features.find_method.engine').run(provider)
end

return M
