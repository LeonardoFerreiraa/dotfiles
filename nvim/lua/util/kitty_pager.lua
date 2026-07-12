return function(input_line_number, cursor_line, cursor_column)
  vim.opt.scrollback = 100000

  local term_buf = vim.api.nvim_create_buf(true, false)
  local term_io = vim.api.nvim_open_term(term_buf, {})
  vim.api.nvim_buf_set_keymap(term_buf, 'n', '<Esc><Esc>', '<Cmd>q<CR>', {})

  local group = vim.api.nvim_create_augroup('kitty_pager', {})

  local function set_cursor()
    vim.api.nvim_feedkeys(tostring(input_line_number) .. 'ggzt', 'n', true)
    local line_count = vim.api.nvim_buf_line_count(term_buf)
    local line = cursor_line <= line_count and cursor_line or line_count
    vim.api.nvim_feedkeys(tostring(line - 1) .. 'j', 'n', true)
    vim.api.nvim_feedkeys('0', 'n', true)
    vim.api.nvim_feedkeys(tostring(cursor_column - 1) .. 'l', 'n', true)
  end

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    buffer = term_buf,
    callback = function()
      if vim.fn.mode() == 't' then
        vim.cmd.stopinsert()
        vim.schedule(set_cursor)
      end
    end,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    pattern = '*',
    once = true,
    callback = function(ev)
      local current_win = vim.fn.win_getid()
      local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
      for i, line in ipairs(lines) do
        vim.api.nvim_chan_send(term_io, line)
        if i < #lines then
          vim.api.nvim_chan_send(term_io, '\r\n')
        end
      end
      vim.api.nvim_win_set_buf(current_win, term_buf)
      vim.api.nvim_buf_delete(ev.buf, { force = true })
      vim.schedule(set_cursor)
    end,
  })
end
