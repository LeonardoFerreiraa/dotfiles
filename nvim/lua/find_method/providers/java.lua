-- Java "find method" provider (jdtls). See find_method/engine.lua.
local P = {
  name = 'java',
  filetypes = { 'java' },
  client_name = 'jdtls',
}

-- LSP SymbolKind for an interface (whose members are implicitly public).
local KIND_INTERFACE = 11

-- jdtls's hover signature omits access modifiers, so visibility is read from
-- the loaded class source: the declaration text between the member's full
-- range start (where modifiers live) and its name. Interface members carry no
-- modifier but are implicitly public; a class/enum member with no explicit
-- modifier is package-private, i.e. not public.
function P.is_public(bufnr, sym, class_sym)
  if class_sym.kind == KIND_INTERFACE then
    return true
  end
  local decl = table.concat(
    vim.api.nvim_buf_get_lines(bufnr, sym.range.start.line, sym.selectionRange.start.line + 1, false),
    ' '
  )
  if decl:find('%f[%a]private%f[%A]') or decl:find('%f[%a]protected%f[%A]') then
    return false
  end
  return decl:find('%f[%a]public%f[%A]') ~= nil
end

-- Drops the repeated declaring-class qualifier jdtls renders in each signature
-- (e.g. `String java.lang.String.substring(int)` -> `String substring(int)`),
-- since it's identical for every member of the same class.
function P.clean_signature(sig, fqn)
  sig = sig:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  local escaped = fqn:gsub('(%W)', '%%%1')
  return (sig:gsub(escaped .. '%.', ''))
end

return P
