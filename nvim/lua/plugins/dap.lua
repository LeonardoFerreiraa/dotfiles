local lsp_enabled = not vim.g.no_lsp

return {
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
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      dapui.setup()

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

      local map = vim.keymap.set
      map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: toggle breakpoint' })
      map('n', '<leader>dB', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = 'DAP: conditional breakpoint' })
      map('n', '<leader>dc', dap.continue, { desc = 'DAP: continue / start' })
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
      local function current_expr()
        if vim.fn.mode() ~= 'v' then
          return vim.fn.expand('<cexpr>')
        end
        local s_line, s_col = unpack(vim.fn.getpos('v'), 2, 3)
        local e_line, e_col = unpack(vim.fn.getpos('.'), 2, 3)
        if s_line > e_line or (s_line == e_line and s_col > e_col) then
          s_line, e_line, s_col, e_col = e_line, s_line, e_col, s_col
        end
        local lines = vim.fn.getline(s_line, e_line)
        if #lines == 0 then
          return ''
        end
        lines[#lines] = lines[#lines]:sub(1, e_col)
        lines[1] = lines[1]:sub(s_col)
        return table.concat(lines, '\n')
      end

      map({ 'n', 'v' }, '<leader>dw', function()
        dapui.elements.watches.add(vim.fn.input('Watch: ', current_expr()))
      end, { desc = 'DAP: add expression to watches' })
    end,
  },
}
