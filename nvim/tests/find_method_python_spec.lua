-- Unit tests for the Python find-method provider: is_public (leading-underscore
-- convention, dunders count as public) and clean_signature (pure whitespace
-- normalisation).
local t = require('tests.harness')
local python = require('features.find_method.providers.python')

local function member(name)
  return { name = name }
end

t.describe('find_method python is_public', function()
  t.it('plain name -> public', function()
    t.eq(python.is_public(0, member('run'), {}), true)
  end)

  t.it('leading underscore -> private', function()
    t.eq(python.is_public(0, member('_helper'), {}), false)
  end)

  t.it('name-mangled (leading __ , no trailing __) -> private', function()
    t.eq(python.is_public(0, member('__secret'), {}), false)
  end)

  t.it('dunder -> public', function()
    t.eq(python.is_public(0, member('__init__'), {}), true)
    t.eq(python.is_public(0, member('__str__'), {}), true)
  end)

  t.it('ignores a trailing signature on the name', function()
    t.eq(python.is_public(0, member('run(self, x)'), {}), true)
  end)
end)

t.describe('find_method python clean_signature', function()
  t.it('collapses whitespace and trims', function()
    t.eq(python.clean_signature('  def   foo( x )  ', 'mod.C'), 'def foo( x )')
  end)
end)
