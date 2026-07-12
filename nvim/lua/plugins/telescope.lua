return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    defaults = {
      layout_config = { prompt_position = 'top' },
      sorting_strategy = 'ascending',
      path_display = { 'shorten' },
      wrap_results = true,
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--follow',
        '--no-require-git',
      },
    },
    pickers = {
      find_files = {
        find_command = { 'rg', '--files', '--hidden', '--follow', '--no-require-git', '--glob', '!.git/*', '--glob', '!*.class' },
      },
      buffers = {
        mappings = {
          n = {
            ['dd'] = function(...) return require('telescope.actions').delete_buffer(...) end,
            ['w'] = function()
              local selection = require('telescope.actions.state').get_selected_entry()
              vim.api.nvim_buf_call(selection.bufnr, function() vim.cmd('write') end)
            end,
          },
        },
      },
    },
  },
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
    { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'Help tags' },
    { '<leader>fw', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics (warnings/errors)' },
    { '<leader>fu', function() require('lsp.lsp_extras').references() end, desc = 'Find usages (LSP references, com loading)' },
    { '<leader><BS>', function() require('features.command_palette').open() end, desc = 'Command palette' },
  },
}
