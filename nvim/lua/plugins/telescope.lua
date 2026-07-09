return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    defaults = {
      -- prompt (search bar) at the top instead of the bottom, with results
      -- listed top-down so the best match sits right under the prompt.
      layout_config = { prompt_position = 'top' },
      sorting_strategy = 'ascending',
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
        -- honor .gitignore/.ignore even when the dir isn't a git repo (rg's
        -- default --require-git skips them without a .git, so build output
        -- like build/ and *.class would otherwise leak into results).
        '--no-require-git',
      },
    },
    pickers = {
      find_files = {
        -- same reasoning: follow symlinks so find_files works inside
        -- ~/v-workspace.
        -- !*.class drops compiled artifacts that slip through when a build
        -- output dir isn't gitignored (e.g. Eclipse/VSCode's bin/) — never a
        -- find-files target regardless of git state.
        find_command = { 'rg', '--files', '--hidden', '--follow', '--no-require-git', '--glob', '!.git/*', '--glob', '!*.class' },
      },
      buffers = {
        -- dd (normal mode, like deleting a line) closes the buffer under
        -- the cursor without leaving the picker (not mapped by default in
        -- this telescope version). Wrapped in a function so the `require`
        -- only runs when pressed, since telescope.nvim isn't guaranteed to
        -- be on the runtimepath yet when this spec table is built.
        mappings = {
          n = {
            ['dd'] = function(...) return require('telescope.actions').delete_buffer(...) end,
            -- w saves the buffer under the cursor without leaving the picker.
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
    { '<leader>fu', function() require('lsp_extras').references() end, desc = 'Find usages (LSP references, com loading)' },
    { '<leader><BS>', function() require('command_palette').open() end, desc = 'Command palette' },
  },
}
