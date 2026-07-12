-- Unit tests for the Java copy-FQN provider's build_fqn: the pure-ish symbol
-- path -> `pkg.Outer.Inner#member` rendering. No LSP needed; we hand it a
-- fabricated DocumentSymbol path and a scratch buffer for the package line.
local t = require('tests.harness')
local java = require('features.copy_fqn.providers.java')

local KIND_CLASS, KIND_METHOD, KIND_ENUM = 5, 6, 10

-- Scratch buffer whose first lines carry the `package ...;` declaration.
local function buf_with_package(pkg)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, pkg and { 'package ' .. pkg .. ';' } or { 'class C {}' })
  return buf
end

local function sym(kind, name)
  return { kind = kind, name = name }
end

t.describe('copy_fqn java build_fqn', function()
  t.it('class#method', function()
    local buf = buf_with_package('com.foo.bar')
    local fqn = java.build_fqn(buf, { sym(KIND_CLASS, 'MyClass'), sym(KIND_METHOD, 'doThing') })
    t.eq(fqn, 'com.foo.bar.MyClass#doThing')
  end)

  t.it('nested class dot-joins, member gets #', function()
    local buf = buf_with_package('a.b')
    local fqn = java.build_fqn(buf, { sym(KIND_CLASS, 'Outer'), sym(KIND_CLASS, 'Inner'), sym(KIND_METHOD, 'm') })
    t.eq(fqn, 'a.b.Outer.Inner#m')
  end)

  t.it('anything nested past the first member falls back to dot', function()
    local buf = buf_with_package('a')
    local fqn = java.build_fqn(buf, { sym(KIND_CLASS, 'C'), sym(KIND_METHOD, 'm'), sym(KIND_CLASS, 'Local') })
    t.eq(fqn, 'a.C#m.Local')
  end)

  t.it('enum is class-like', function()
    local buf = buf_with_package('a')
    local fqn = java.build_fqn(buf, { sym(KIND_ENUM, 'E'), sym(KIND_METHOD, 'values') })
    t.eq(fqn, 'a.E#values')
  end)

  t.it('no package declaration -> bare class name', function()
    local buf = buf_with_package(nil)
    local fqn = java.build_fqn(buf, { sym(KIND_CLASS, 'C') })
    t.eq(fqn, 'C')
  end)
end)
