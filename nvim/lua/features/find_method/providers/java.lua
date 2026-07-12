local P = {
  name = 'java',
  filetypes = { 'java' },
  client_name = 'jdtls',
}

local KIND_INTERFACE = 11

function P.is_public(bufnr, sym, class_sym)
  if class_sym.kind == KIND_INTERFACE then
    return true
  end
  local decl = table.concat(
    vim.api.nvim_buf_get_lines(bufnr, sym.range.start.line, sym.selectionRange.start.line + 1, false),
    ' '
  )
  decl = decl:gsub('/%*.-%*/', ''):gsub('//[^\n]*', '')
  if decl:find('%f[%a]private%f[%A]') or decl:find('%f[%a]protected%f[%A]') then
    return false
  end
  return decl:find('%f[%a]public%f[%A]') ~= nil
end

function P.clean_signature(sig, fqn)
  sig = sig:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  local escaped = fqn:gsub('(%W)', '%%%1')
  return (sig:gsub(escaped .. '%.', ''))
end

return P
