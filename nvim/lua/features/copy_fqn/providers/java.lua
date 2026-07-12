local P = {
  name = 'java',
  filetypes = { 'java' },
  client_name = 'jdtls',
}

local KIND_CLASS = 5
local KIND_ENUM = 10
local KIND_INTERFACE = 11
local CLASS_LIKE = { [KIND_CLASS] = true, [KIND_ENUM] = true, [KIND_INTERFACE] = true }

local function package_name(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
    local pkg = line:match('^%s*package%s+([%w%.]+)%s*;')
    if pkg then
      return pkg
    end
  end
  return nil
end

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
