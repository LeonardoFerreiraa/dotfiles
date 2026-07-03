-- Terminal buffers (toggleterm) should behave like a normal buffer with
-- normal/insert/visual modes: <Space> should not be hijacked by leader while
-- navigating in terminal-normal mode, and <Esc> should leave terminal-job
-- (insert) mode without needing <C-\><C-n>.
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function(args)
    vim.keymap.set({ 'n', 'x' }, '<Space>', '<Space>', { buffer = args.buf, silent = true })
    vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { buffer = args.buf, silent = true })
  end,
})
