-- Java "copy FQN" provider (jdtls). See copy_fqn/engine.lua.
local P = {
  name = 'java',
  filetypes = { 'java' },
  client_name = 'jdtls',
}

-- LSP SymbolKind values (1-indexed per the spec).
local KIND_CLASS = 5
local KIND_ENUM = 10
local KIND_INTERFACE = 11
local CLASS_LIKE = { [KIND_CLASS] = true, [KIND_ENUM] = true, [KIND_INTERFACE] = true }

-- Reads the `package x.y.z;` declaration from the top of the buffer, if any.
local function package_name(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
    local pkg = line:match('^%s*package%s+([%w%.]+)%s*;')
    if pkg then
      return pkg
    end
  end
  return nil
end

-- Joins the symbol path (root..leaf) into `pkg.Outer.Inner#member`: class-like
-- symbols (class/enum/interface, including nested types) are dot-joined; the
-- first non-class-like symbol (method/field/enum constant) is joined with
-- '#', matching IntelliJ's "Copy Reference" format. Anything nested past that
-- (e.g. a local class inside a method) falls back to '.'.
function P.build_fqn(bufnr, path)
  local fqn = package_name(bufnr) or ''
  local seen_member = false

  for _, sym in ipairs(path) do
    if CLASS_LIKE[sym.kind] then
      fqn = (fqn ~= '' and (fqn .. '.') or '') .. sym.name
    elseif not seen_member then
      fqn = fqn .. '#' .. sym.name
      seen_member = true
    else
      fqn = fqn .. '.' .. sym.name
    end
  end

  return fqn
end

return P
