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

-- Plugin specs live in lua/plugins/*.lua (one file/group per return table).
require('lazy').setup('plugins')

-- LSP/jdtls autocmds and keymaps. Kept after lazy.setup() to mirror the
-- original ordering: plugins are on the runtimepath and Neovim's default
-- LSP mappings (e.g. `gra`) exist and can be unmapped.
require('config.lsp')
