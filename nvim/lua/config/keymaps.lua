vim.g.mapleader = ' '

vim.keymap.set({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', '<leader>l', ':nohls<CR>', { silent = true })
vim.keymap.set('n', '<leader>gb', '<C-o>', { desc = 'Jump back' })
vim.keymap.set('n', '<leader>gf', '<C-i>', { desc = 'Jump forward' })

vim.keymap.set('n', '<leader>nh', '<C-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<leader>nj', '<C-w>j', { desc = 'Go to window below' })
vim.keymap.set('n', '<leader>nk', '<C-w>k', { desc = 'Go to window above' })
vim.keymap.set('n', '<leader>nl', '<C-w>l', { desc = 'Go to right window' })

vim.keymap.set({ 'n', 'v' }, '<leader>gh', '^', { desc = 'Go to line start' })
vim.keymap.set({ 'n', 'v' }, '<leader>gl', '$', { desc = 'Go to line end' })

vim.keymap.set('n', '<Home>', '^', { desc = 'Go to line start' })
vim.keymap.set('n', '<End>', '$', { desc = 'Go to line end' })
vim.keymap.set('i', '<Home>', '<C-o>^', { desc = 'Go to line start' })
vim.keymap.set('i', '<End>', '<C-o>$', { desc = 'Go to line end' })

vim.keymap.set('i', '<C-Left>', '<C-o>b', { desc = 'Jump word back' })
vim.keymap.set('i', '<C-Right>', '<C-o>w', { desc = 'Jump word forward' })

vim.keymap.set('n', '<Esc>', ':silent! update<CR>', { desc = 'Save (Esc in Normal mode)' })

vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste over selection without yanking it' })
