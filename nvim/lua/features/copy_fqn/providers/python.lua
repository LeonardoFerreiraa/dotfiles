local P = {
  name = 'python',
  filetypes = { 'python' },
  client_name = 'basedpyright',
}

local function module_name(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    return ''
  end
  file = vim.fs.normalize(file)
  local dir = vim.fs.dirname(file)
  local base = vim.fn.fnamemodify(file, ':t:r')
  local parts = {}
  if base ~= '__init__' then
    table.insert(parts, base)
  end
  while vim.uv.fs_stat(dir .. '/__init__.py') do
    table.insert(parts, 1, vim.fs.basename(dir))
    dir = vim.fs.dirname(dir)
  end
  return table.concat(parts, '.')
end

function P.build_fqn(bufnr, path)
  local parts = {}
  local mod = module_name(bufnr)
  if mod ~= '' then
    table.insert(parts, mod)
  end
  for _, sym in ipairs(path) do
    table.insert(parts, (sym.name:gsub('%s*%(.*$', '')))
  end
  return table.concat(parts, '.')
end

return P
