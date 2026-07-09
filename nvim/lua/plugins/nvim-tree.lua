return {
  'nvim-tree/nvim-tree.lua',
  -- file-type icons in the tree (needs a Nerd Font in the terminal to render).
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,
  config = function()
    require('nvim-tree').setup({
      -- netrw is disabled in lua/config/options.lua; let nvim-tree take over
      -- directory buffers so `nvim <dir>` / `:edit <dir>` render the tree in
      -- the current window (full window, netrw-style) instead of a side panel.
      hijack_netrw = true,
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      view = {
        -- nvim-tree hides line numbers by default; show absolute+relative
        -- (hybrid) numbers like the rest of the editor.
        number = true,
        relativenumber = true,
        -- open as a centered floating popup (like the original toggleterm
        -- float) instead of a side split.
        float = {
          enable = true,
          open_win_config = function()
            local screen_w = vim.opt.columns:get()
            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
            local w = math.floor(screen_w * 0.8)
            local h = math.floor(screen_h * 0.8)
            return {
              relative = 'editor',
              border = 'rounded',
              width = w,
              height = h,
              row = math.floor((screen_h - h) / 2),
              col = math.floor((screen_w - w) / 2),
            }
          end,
        },
      },
      renderer = {
        -- collapse chains of single-child directories into one line, e.g.
        -- br/com/pagbank/watchdog shows as a single node (Java packages).
        group_empty = true,
      },
      actions = {
        open_file = {
          -- close the tree when opening a file so the file replaces the
          -- (full-window) tree in place, instead of nvim-tree splitting off a
          -- side panel to keep itself open. Gives netrw's open-in-same-window
          -- feel.
          quit_on_open = true,
          -- With a debug session running, dap-ui opens several panels
          -- (scopes/stacks/breakpoints/watches/repl/console). nvim-tree then
          -- sees multiple candidate windows and prompts "pick a window" for
          -- where to open the file. Exclude the dap-ui panels (and terminal
          -- buffers, i.e. the repl/console) so only the real code window is
          -- eligible — the file opens there directly, no prompt.
          window_picker = {
            enable = true,
            exclude = {
              filetype = {
                'dapui_scopes',
                'dapui_breakpoints',
                'dapui_stacks',
                'dapui_watches',
                'dapui_console',
                'dapui_hover',
                'dap-repl',
              },
              buftype = { 'terminal', 'nofile' },
            },
          },
        },
      },
    })

    -- `-` opens the floating tree and reveals (cursor on) the file you were
    -- editing, mimicking the old netrw `-`. update_root keeps the current
    -- file visible even if it lives outside the current root.
    vim.keymap.set('n', '-', function()
      require('nvim-tree.api').tree.find_file({ open = true, focus = true, update_root = true })
    end, { desc = 'Open floating tree at current file (nvim-tree)' })

    -- Double <Esc> closes the floating tree, matching Telescope's dismiss.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'NvimTree',
      callback = function(args)
        vim.keymap.set('n', '<Esc><Esc>', function()
          require('nvim-tree.api').tree.close()
        end, { buffer = args.buf, silent = true, desc = 'Close nvim-tree float' })
      end,
    })
  end,
}
