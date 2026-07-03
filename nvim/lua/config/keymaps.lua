-- mapleader must be set before lazy.setup() loads plugins (required from
-- init.lua ahead of the lazy call, see the note there).
vim.g.mapleader = ' '

-- Space normally moves the cursor right in normal mode; disable that so it
-- doesn't fire before leader mappings are processed.
vim.keymap.set({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', '<leader>l', ':nohls<CR>', { silent = true })
-- jumplist navigation (e.g. back/forward after gd, <leader>fu, <leader>fd, etc.)
vim.keymap.set('n', '<leader>gb', '<C-o>', { desc = 'Jump back' })
vim.keymap.set('n', '<leader>gf', '<C-i>', { desc = 'Jump forward' })

-- Pane/window navigation with <leader>n + hjkl (works from a normal split
-- and also straight out of a terminal buffer, without needing <Esc> first).
vim.keymap.set('n', '<leader>nh', '<C-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<leader>nj', '<C-w>j', { desc = 'Go to window below' })
vim.keymap.set('n', '<leader>nk', '<C-w>k', { desc = 'Go to window above' })
vim.keymap.set('n', '<leader>nl', '<C-w>l', { desc = 'Go to right window' })
-- Not mapped in terminal-job (insert) mode: since <leader> is <Space>, doing
-- so would make every <Space> keystroke while typing in the terminal wait
-- for the mapping timeout. Use <Esc> to reach terminal-normal mode first,
-- then <leader>nh/j/k/l from there.

-- Line start/end navigation with <leader>g + h/l
vim.keymap.set('n', '<leader>gh', '^', { desc = 'Go to line start' })
vim.keymap.set('n', '<leader>gl', '$', { desc = 'Go to line end' })

-- `-` opens the parent directory in oil (see lua/plugins/oil.lua).
