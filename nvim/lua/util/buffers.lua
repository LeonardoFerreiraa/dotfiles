local M = {}

function M.close_others()
  local cur = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
end

vim.api.nvim_create_user_command('CloseOtherBuffers', M.close_others, { desc = 'Close all buffers except the current one' })

return M
