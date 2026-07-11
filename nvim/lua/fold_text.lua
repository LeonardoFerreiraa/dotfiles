-- `vim.lsp.foldtext()` falls back to the raw, unformatted first source line
-- when the server doesn't supply `collapsedText` for a fold. jdtls doesn't
-- send one, so a folded Javadoc/comment block would show its literal first
-- line (e.g. "/**") instead of a useful summary. Detect that fallback and
-- build a cleaner one-line preview for comment folds; anything else (or a
-- server that *did* supply collapsedText) passes through untouched.
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
