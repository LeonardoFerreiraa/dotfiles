return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,
  config = function()
    require('nvim-tree').setup({
      hijack_netrw = true,
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      view = {
        number = true,
        relativenumber = true,
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
        group_empty = true,
      },
      actions = {
        open_file = {
          quit_on_open = true,
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

    vim.keymap.set('n', '-', function()
      require('nvim-tree.api').tree.find_file({ open = true, focus = true, update_root = true })
    end, { desc = 'Open floating tree at current file (nvim-tree)' })

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
