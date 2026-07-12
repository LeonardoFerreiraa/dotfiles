require('lsp.hover_box').setup()
require('lsp.workspace_undo').setup()

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function(args)
    require('lsp.jdtls_config').setup(args.buf)
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaSetJdk', function()
      require('lsp.jdtls_config').pick_jdk_and_start()
    end, { desc = 'Pick a JDK (via cli-assistant) and (re)start jdtls' })
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaReindex', function()
      require('lsp.jdtls_config').reindex()
    end, { desc = 'Wipe jdtls workspace data and restart (full re-index)' })
  end,
})

vim.api.nvim_create_user_command('FindMethod', function()
  require('features.find_method').open()
end, { desc = 'Find & jump to a public method/member of any reachable class' })

vim.api.nvim_create_user_command('CopyFQN', function()
  require('features.copy_fqn').run()
end, { desc = 'Copy fully-qualified name/reference of the symbol under the cursor' })

pcall(vim.keymap.del, 'n', '<C-w>d')
vim.keymap.set('n', '<leader>sd', vim.diagnostic.open_float, { desc = 'Show diagnostic under cursor' })

vim.keymap.set('n', 'u', function()
  require('lsp.workspace_undo').smart_undo()
end, { desc = 'Undo (workspace-edit aware)' })

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
      require('lsp.lsp_extras').definitions_and_declarations,
      vim.tbl_extend('force', opts, { desc = 'Definitions & declarations (Telescope, deduped)' })
    )
    vim.keymap.set(
      'n',
      '<leader>ca',
      require('lsp.lsp_extras').code_actions,
      vim.tbl_extend('force', opts, { desc = 'Code actions (Telescope, com loading)' })
    )
    vim.keymap.set('n', '<leader>cf', function()
      vim.lsp.buf.format({ async = true })
    end, vim.tbl_extend('force', opts, { desc = 'Format document' }))
  end,
})
