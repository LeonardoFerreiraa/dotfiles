-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Editor settings and keymaps. config.keymaps sets mapleader, so it must run
-- before lazy.setup() below: lazy expands <leader> in plugin `keys` specs at
-- load time, and would otherwise use the wrong leader.
require('config.options')
require('config.keymaps')
require('buffers')

-- kitty's scrollback_pager (kitty.conf) invokes this same config via
-- `nvim -c "lua require('kitty_pager')(...)"` so it gets colors/plugins/
-- keymaps, but jdtls/mason/lspconfig are the heaviest part of startup and
-- pointless for a readonly scrollback dump. Detect that invocation from
-- argv (no env var / wrapper script needed) and skip them, see
-- lua/plugins/lsp.lua.
vim.g.no_lsp = false
for _, arg in ipairs(vim.v.argv) do
  if arg:find('kitty_pager', 1, true) then
    vim.g.no_lsp = true
    break
  end
end

-- Plugin specs live in lua/plugins/*.lua (one file/group per return table).
require('lazy').setup('plugins')

-- LSP/jdtls autocmds and keymaps. Kept after lazy.setup() to mirror the
-- original ordering: plugins are on the runtimepath and Neovim's default
-- LSP mappings (e.g. `gra`) exist and can be unmapped. Skipped under
-- vim.g.no_lsp (see above) since the servers it wires up keymaps for
-- aren't loaded anyway.
if not vim.g.no_lsp then
  require('config.lsp')
end
