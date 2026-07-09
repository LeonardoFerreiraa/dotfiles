-- Language-agnostic "copy FQN" (see engine.lua). Dispatches to a provider by
-- the current buffer's filetype. Register a new language by adding it here
-- and dropping a copy_fqn/providers/<name>.lua alongside it.
local M = {}

local PROVIDER_NAMES = { 'java' }

-- Builds a filetype -> provider map from the registered providers.
local function providers_by_filetype()
  local map = {}
  for _, name in ipairs(PROVIDER_NAMES) do
    local ok, provider = pcall(require, 'copy_fqn.providers.' .. name)
    if ok then
      for _, ft in ipairs(provider.filetypes or {}) do
        map[ft] = provider
      end
    end
  end
  return map
end

-- Copies the FQN/reference of the symbol under the cursor for the current
-- buffer's filetype.
function M.run()
  local ft = vim.bo.filetype
  local provider = providers_by_filetype()[ft]
  if not provider then
    vim.notify('CopyFQN: sem provider para o filetype "' .. ft .. '"', vim.log.levels.WARN)
    return
  end
  require('copy_fqn.engine').run(provider)
end

return M
