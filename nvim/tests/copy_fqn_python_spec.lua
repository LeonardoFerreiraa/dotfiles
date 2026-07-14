-- Unit tests for the Python copy-FQN provider's build_fqn: module (from the
-- buffer's file path + __init__.py package walk) joined with the dotted symbol
-- path. A file under a dir with no __init__.py resolves to a bare module name,
-- which keeps this deterministic without touching the real filesystem.
local t = require('tests.harness')
local python = require('features.copy_fqn.providers.python')

local KIND_CLASS, KIND_METHOD = 5, 6

local function buf_named(path)
  local buf = vim.api.nvim_create_buf(false, true)
  if path then
    vim.api.nvim_buf_set_name(buf, path)
  end
  return buf
end

local function sym(kind, name)
  return { kind = kind, name = name }
end

t.describe('copy_fqn python build_fqn', function()
  t.it('joins module and symbols with dots', function()
    local buf = buf_named('/no/such/dir/mymod.py')
    local fqn = python.build_fqn(buf, { sym(KIND_CLASS, 'MyClass'), sym(KIND_METHOD, 'do_thing') })
    t.eq(fqn, 'mymod.MyClass.do_thing')
  end)

  t.it('unnamed buffer -> just the dotted symbol path', function()
    local fqn = python.build_fqn(buf_named(nil), { sym(KIND_CLASS, 'C'), sym(KIND_METHOD, 'm') })
    t.eq(fqn, 'C.m')
  end)

  t.it('strips a trailing signature from the symbol name', function()
    local fqn = python.build_fqn(buf_named(nil), { sym(KIND_CLASS, 'C'), sym(KIND_METHOD, 'm(self, x)') })
    t.eq(fqn, 'C.m')
  end)
end)
