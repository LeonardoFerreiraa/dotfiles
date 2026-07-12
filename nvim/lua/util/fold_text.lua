local M = {}

function M.get()
  local start_line = vim.v.foldstart
  local raw = vim.fn.getline(start_line)

  local lsp_text = vim.lsp.foldtext()
  if lsp_text ~= raw then
    return lsp_text
  end

  if raw:match('^%s*/[*/]') then
    local finish = vim.v.foldend
    for lnum = start_line, finish do
      local clean = vim.fn.getline(lnum):gsub('^%s*/?%*+/?%s?', ''):gsub('%s+$', '')
      if clean ~= '' then
        return string.format('/** %s */ (%d lines)', clean, finish - start_line + 1)
      end
    end
  end

  return raw
end

return M
