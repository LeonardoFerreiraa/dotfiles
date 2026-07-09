-- Java debugging. nvim-dap is a generic Debug Adapter Protocol client; the
-- actual Java adapter (java-debug-adapter) and the JUnit runner (java-test)
-- are loaded *into* the running jdtls server as bundles, not as standalone
-- processes — see lua/jdtls_config.lua (debug_bundles + on_attach). So there
-- is no separate debug server: the same jdtls that powers LSP also drives
-- debug, reusing the per-project $JAVA_HOME managed by cli-assistant.
--
-- Skipped under vim.g.no_lsp (kitty scrollback pager invocation) for the same
-- reason lsp.lua is: pointless weight for a readonly dump.
local lsp_enabled = not vim.g.no_lsp

return {
  -- mason-lspconfig's ensure_installed only handles LSP servers; the debug
  -- adapter and test runner are Mason "tools", so a separate installer is
  -- needed to auto-install them alongside jdtls.
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    enabled = lsp_enabled,
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'java-debug-adapter', 'java-test' },
    },
  },

  {
    'mfussenegger/nvim-dap',
    enabled = lsp_enabled,
    dependencies = {
      -- dap-ui gives the scopes/stacks/breakpoints/watches/repl panels;
      -- nvim-nio is its required async runtime.
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      dapui.setup()

      -- Open the UI when a debug session starts, close it when it ends, so the
      -- panels are only present while actually debugging.
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end

      vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
      vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'Visual' })

      -- Debug keymaps live under <leader>d (free: keymaps.lua uses g/n/s/c/f/l).
      local map = vim.keymap.set
      map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: toggle breakpoint' })
      map('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = 'DAP: conditional breakpoint' })
      map('n', '<leader>dc', dap.continue, { desc = 'DAP: continue / start' })
      -- Remote attach to a JVM started with JDWP (e.g. `./gradlew bootRun
      -- --debug-jvm`, which listens on :5005). Run ad-hoc via dap.run instead
      -- of dap.configurations.java because jdtls' setup_dap_main_class_configs
      -- overwrites that list with launch-only configs on every attach.
      map('n', '<leader>da', function()
        local port = tonumber(vim.fn.input('Attach to JDWP port: ', '5005'))
        if not port then
          return
        end
        dap.run({
          type = 'java',
          request = 'attach',
          name = 'Attach :' .. port,
          hostName = '127.0.0.1',
          port = port,
        })
      end, { desc = 'DAP: attach to remote JVM (JDWP)' })
      map('n', '<leader>dn', dap.step_over, { desc = 'DAP: step over' })
      map('n', '<leader>di', dap.step_into, { desc = 'DAP: step into' })
      map('n', '<leader>do', dap.step_out, { desc = 'DAP: step out' })
      map('n', '<leader>dr', dap.repl.toggle, { desc = 'DAP: toggle REPL' })
      map('n', '<leader>dt', dap.terminate, { desc = 'DAP: terminate session' })
      map('n', '<leader>du', dapui.toggle, { desc = 'DAP: toggle UI' })
      map({ 'n', 'v' }, '<leader>de', function()
        dapui.eval()
      end, { desc = 'DAP: eval expression under cursor' })
    end,
  },
}
