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

opt.clipboard = 'unnamedplus'

opt.undofile = true
opt.undodir = vim.fn.stdpath('data') .. '/undodir'
opt.undolevels = 1000

opt.diffopt:append('vertical')

opt.list = true
opt.listchars = { tab = '▶ ', trail = '·' }

opt.hidden = true

opt.foldmethod = 'expr'
opt.foldexpr = 'v:lua.vim.lsp.foldexpr()'
opt.foldtext = "v:lua.require('util.fold_text').get()"
opt.foldlevelstart = 99

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
