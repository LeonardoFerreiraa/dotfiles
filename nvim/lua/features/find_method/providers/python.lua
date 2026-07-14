local P = {
  name = 'python',
  filetypes = { 'python' },
  client_name = 'basedpyright',
}

local function is_dunder(name)
  return name:match('^__.+__$') ~= nil
end

function P.is_public(bufnr, sym, class_sym)
  local name = (sym.name or ''):gsub('%s*%(.*$', '')
  if is_dunder(name) then
    return true
  end
  return not vim.startswith(name, '_')
end

function P.clean_signature(sig, fqn)
  return (sig:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

return P
