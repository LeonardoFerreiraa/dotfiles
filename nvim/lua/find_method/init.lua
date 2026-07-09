-- Language-agnostic "find method" (see engine.lua). Dispatches to a provider
-- by the current buffer's filetype. Register a new language by adding it here
-- and dropping a find_method/providers/<name>.lua alongside it.
local M = {}

local PROVIDER_NAMES = { 'java' }

-- Builds a filetype -> provider map from the registered providers.
local function providers_by_filetype()
  local map = {}
  for _, name in ipairs(PROVIDER_NAMES) do
    local ok, provider = pcall(require, 'find_method.providers.' .. name)
    if ok then
      for _, ft in ipairs(provider.filetypes or {}) do
        map[ft] = provider
      end
    end
  end
  return map
end

-- Opens the finder for the current buffer's filetype.
function M.open()
  local ft = vim.bo.filetype
  local provider = providers_by_filetype()[ft]
  if not provider then
    vim.notify('find_method: sem provider para o filetype "' .. ft .. '"', vim.log.levels.WARN)
    return
  end
  require('find_method.engine').run(provider)
end

return M
