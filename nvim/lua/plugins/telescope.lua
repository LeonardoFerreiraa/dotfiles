return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    defaults = {
      -- shortens each directory segment of the path (e.g. Java packages
      -- like br/com/pagbank/watchdog/...) down to a couple characters,
      -- keeping the filename itself untruncated.
      path_display = { 'shorten' },
      -- wraps long result lines (e.g. long diagnostic/warning messages)
      -- instead of cutting them off at the window edge.
      wrap_results = true,
      -- follow symlinks during live_grep (ripgrep ignores them otherwise)
      -- needed for ~/v-workspace, which is made of symlinks to real repos.
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--follow',
      },
    },
    pickers = {
      find_files = {
        -- same reasoning: follow symlinks so find_files works inside
        -- ~/v-workspace.
        find_command = { 'rg', '--files', '--hidden', '--follow', '--glob', '!.git/*' },
      },
    },
  },
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
    { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'Help tags' },
    { '<leader>fw', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics (warnings/errors)' },
    { '<leader>fu', function() require('lsp_extras').references() end, desc = 'Find usages (LSP references, com loading)' },
  },
}
