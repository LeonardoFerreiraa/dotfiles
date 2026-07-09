-- jdtls is started via a plain FileType autocmd (not ftplugin/java.lua)
-- because Neovim loads ftplugin/*.lua before lazy.nvim finishes putting
-- plugins on the runtimepath, causing "module 'jdtls' not found" when a
-- .java file is opened directly from the command line (nvim file.java).
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function(args)
    require('jdtls_config').setup(args.buf)
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaSetJdk', function()
      require('jdtls_config').pick_jdk_and_start()
    end, { desc = 'Pick a JDK (via cli-assistant) and (re)start jdtls' })
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaReindex', function()
      require('jdtls_config').reindex()
    end, { desc = 'Wipe jdtls workspace data and restart (full re-index)' })
  end,
})

-- Language-agnostic: dispatches to a provider by the buffer's filetype (java
-- for now). Global so it works from the command palette in any buffer;
-- find_method guards when no provider/LSP matches.
vim.api.nvim_create_user_command('FindMethod', function()
  require('find_method').open()
end, { desc = 'Find & jump to a public method/member of any reachable class' })

vim.api.nvim_create_user_command('CopyFQN', function()
  require('copy_fqn').run()
end, { desc = 'Copy fully-qualified name/reference of the symbol under the cursor' })

-- <leader>sd (show diagnostic) replaces the default `<C-w>d`; unmap the
-- global default once (works on any buffer, not just LSP-attached ones,
-- since diagnostics can also come from non-LSP sources).
pcall(vim.keymap.del, 'n', '<C-w>d')
vim.keymap.set('n', '<leader>sd', vim.diagnostic.open_float, { desc = 'Show diagnostic under cursor' })

-- LSP keymaps: buffer-local, set once a language server attaches to the buffer.
-- <leader>ca (below) replaces the default `gra` code action keymap with a
-- Telescope-based picker; unmap the global default once, globally.
pcall(vim.keymap.del, 'n', 'gra')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set(
      'n',
      '<leader>fd',
      require('lsp_extras').definitions_and_declarations,
      vim.tbl_extend('force', opts, { desc = 'Definitions & declarations (Telescope, deduped)' })
    )
    -- replaces the default `gra` with <leader>ca, showing results in
    -- Telescope (with a loading placeholder) instead of vim.ui.select
    vim.keymap.set(
      'n',
      '<leader>ca',
      require('lsp_extras').code_actions,
      vim.tbl_extend('force', opts, { desc = 'Code actions (Telescope, com loading)' })
    )
    vim.keymap.set('n', '<leader>cf', function()
      vim.lsp.buf.format({ async = true })
    end, vim.tbl_extend('force', opts, { desc = 'Format document' }))
  end,
})
