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

require('config.options')
require('config.keymaps')
require('util.buffers')

vim.g.no_lsp = require('util.pager').is_pager_argv(vim.v.argv)

require('lazy').setup('plugins')

if not vim.g.no_lsp then
  require('config.lsp')
end
