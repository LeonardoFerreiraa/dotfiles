-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

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

vim.g.mapleader = ' '
-- Space normally moves the cursor right in normal mode; disable that so it
-- doesn't fire before leader mappings are processed.
vim.keymap.set({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', '<leader>l', ':nohls<CR>', { silent = true })
-- jumplist navigation (e.g. back/forward after gd, <leader>fu, <leader>fd, etc.)
vim.keymap.set('n', '<leader>gb', '<C-o>', { desc = 'Jump back' })
vim.keymap.set('n', '<leader>gf', '<C-i>', { desc = 'Jump forward' })

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

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25
vim.g.netrw_hide = 1
vim.cmd('packadd! netrw')
-- Builds the hide list from .gitignore automatically. Falls back to empty
-- (i.e. hide nothing extra) outside a git repo, instead of leaking git's
-- "not a git repository" stderr message into the hide pattern.
local ok, gitignore_hide = pcall(vim.fn['netrw_gitignore#Hide'])
vim.g.netrw_list_hide = (ok and not gitignore_hide:match('^fatal:')) and gitignore_hide or ''

vim.keymap.set('n', '-', ':Explore<CR>')

require('lazy').setup({
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        flavour = 'macchiato',
      })
      vim.cmd.colorscheme('catppuccin')
    end,
  },
  {
    'mason-org/mason.nvim',
    config = true,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      ensure_installed = { 'jdtls' },
      -- jdtls is started manually (see lua/jdtls_config.lua) so it can use the
      -- per-project $JAVA_HOME managed by cli-assistant. Without this exclude,
      -- mason-lspconfig also auto-enables nvim-lspconfig's default jdtls config,
      -- which launches a second, conflicting client using a bare `java`/`jdtls`
      -- from PATH (ignoring JAVA_HOME) and fails with "Unable to locate a Java
      -- Runtime".
      automatic_enable = {
        exclude = { 'jdtls' },
      },
    },
  },
  'neovim/nvim-lspconfig',
  'mfussenegger/nvim-jdtls',
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      direction = 'horizontal',
      size = 15,
      open_mapping = [[<leader>t]],
    },
  },
  {
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
  },
})

-- jdtls is started via a plain FileType autocmd (not ftplugin/java.lua)
-- because Neovim loads ftplugin/*.lua before lazy.nvim finishes putting
-- plugins on the runtimepath, causing "module 'jdtls' not found" when a
-- .java file is opened directly from the command line (nvim file.java).
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function(args)
    require('jdtls_config').setup()
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaSetJdk', function()
      require('jdtls_config').pick_jdk_and_start()
    end, { desc = 'Pick a JDK (via cli-assistant) and (re)start jdtls' })
    vim.api.nvim_buf_create_user_command(args.buf, 'JavaReindex', function()
      require('jdtls_config').reindex()
    end, { desc = 'Wipe jdtls workspace data and restart (full re-index)' })
  end,
})

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
  end,
})

