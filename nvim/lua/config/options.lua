local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.autoindent = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smarttab = true
opt.scrolloff = 7

opt.ignorecase = true
opt.incsearch = true
opt.hlsearch = true
opt.smartcase = true

opt.laststatus = 2

vim.cmd('syntax on')
opt.background = 'dark'

opt.wrap = false

opt.mouse = 'a'
opt.mousehide = true

opt.swapfile = false
opt.autoread = true

opt.diffopt:append('vertical')

opt.list = true
opt.listchars = { tab = '▶ ', trail = '·' }

opt.hidden = true

-- Disable netrw entirely; oil.nvim is the directory browser (see
-- lua/plugins/oil.lua). Must be set before netrw's plugin loads at startup.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
