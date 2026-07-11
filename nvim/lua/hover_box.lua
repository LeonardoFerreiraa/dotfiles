-- Customizes the LSP hover float bound to `K`: a rounded border matching the
-- rest of the UI (same style as nvim-tree's popups), inner padding so text
-- isn't flush against the border, a blank line separating a leading
-- code-fenced signature from the prose below it (jdtls in particular renders
-- a class signature and its Javadoc back-to-back with no visual gap), and
-- <Esc> to dismiss (the native float only binds `q`).
local M = {}

function M.setup()
  local open_floating_preview = vim.lsp.util.open_floating_preview

  vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
    opts = opts or {}
    local is_hover = opts.focus_id == 'textDocument/hover'

    if is_hover then
      opts.border = opts.border or 'rounded'

      -- Insert a blank line right after any code fence closes, if prose
      -- follows immediately without one (e.g. signature -> Javadoc).
      local spaced = {}
      local in_fence = false
      for i, line in ipairs(contents) do
        table.insert(spaced, line)
        if line:match('^```') then
          in_fence = not in_fence
          if not in_fence and contents[i + 1] and contents[i + 1] ~= '' then
            table.insert(spaced, '')
          end
        end
      end
      contents = spaced
    end

    local bufnr, winnr = open_floating_preview(contents, syntax, opts, ...)

    if is_hover and winnr and not vim.w[winnr].hover_box then
      vim.w[winnr].hover_box = true

      -- Inner padding: 1 blank line above/below, 1 space left (the window is
      -- widened by 2 below, so the extra column becomes right padding).
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local padded = { '' }
      for _, line in ipairs(lines) do
        table.insert(padded, ' ' .. line)
      end
      table.insert(padded, '')

      vim.bo[bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, padded)
      vim.bo[bufnr].modifiable = false

      local cfg = vim.api.nvim_win_get_config(winnr)
      cfg.height = cfg.height + 2
      cfg.width = cfg.width + 2
      vim.api.nvim_win_set_config(winnr, cfg)

      -- <Esc> closes the box from the source buffer (hover opens unfocused)
      -- and from inside it too (after `KK` jumps focus into the float).
      local src_bufnr = vim.api.nvim_get_current_buf()
      vim.keymap.set('n', '<Esc>', function()
        if vim.api.nvim_win_is_valid(winnr) then
          vim.api.nvim_win_close(winnr, true)
        end
      end, { buffer = src_bufnr, silent = true, nowait = true })
      vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = bufnr, silent = true, nowait = true })

      vim.api.nvim_create_autocmd('WinClosed', {
        pattern = tostring(winnr),
        once = true,
        callback = function()
          pcall(vim.keymap.del, 'n', '<Esc>', { buffer = src_bufnr })
        end,
      })

      -- Focus the box immediately so cursor keys/scrolling work without a
      -- second `K` (native hover opens unfocused).
      vim.api.nvim_win_set_cursor(winnr, { 1, 0 })
      vim.api.nvim_set_current_win(winnr)
    end

    return bufnr, winnr
  end
end

return M
