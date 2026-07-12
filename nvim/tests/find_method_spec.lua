-- Unit tests for the Java find-method provider: clean_signature (pure string)
-- and is_public (reads modifiers from a scratch buffer's source lines).
local t = require('tests.harness')
local java = require('features.find_method.providers.java')

local KIND_CLASS, KIND_INTERFACE = 5, 11

local function scratch(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

-- A member symbol whose declaration occupies a single line at `line`
-- (0-indexed). range.start == where modifiers live; selectionRange.start ==
-- the name, on the same line here.
local function member(line)
  return { range = { start = { line = line } }, selectionRange = { start = { line = line } } }
end

t.describe('find_method java clean_signature', function()
  t.it('drops the repeated declaring-class qualifier', function()
    local sig = java.clean_signature('String  java.lang.String.substring(int)', 'java.lang.String')
    t.eq(sig, 'String substring(int)')
  end)

  t.it('collapses whitespace and trims', function()
    local sig = java.clean_signature('  void   foo( )  ', 'pkg.C')
    t.eq(sig, 'void foo( )')
  end)
end)

t.describe('find_method java is_public', function()
  local src = {
    'public class C {', -- 0
    '  private int x;', -- 1
    '  public void m() {}', -- 2
    '  void pkgPriv() {}', -- 3
    '  protected int p;', -- 4
  }

  t.it('private member -> false', function()
    t.eq(java.is_public(scratch(src), member(1), { kind = KIND_CLASS }), false)
  end)

  t.it('public member -> true', function()
    t.eq(java.is_public(scratch(src), member(2), { kind = KIND_CLASS }), true)
  end)

  t.it('package-private (no modifier) -> false', function()
    -- gsub-based find returns nil for a no-match; assert it's not truthy.
    t.assert(not java.is_public(scratch(src), member(3), { kind = KIND_CLASS }), 'pkg-private should not be public')
  end)

  t.it('protected member -> false', function()
    t.eq(java.is_public(scratch(src), member(4), { kind = KIND_CLASS }), false)
  end)

  t.it('interface members are implicitly public', function()
    t.eq(java.is_public(scratch(src), member(3), { kind = KIND_INTERFACE }), true)
  end)

  t.it('comment prose containing "private" is not misread as a modifier', function()
    local buf = scratch({ '/** calls the private helper */', 'public void m() {}' })
    -- range spans the javadoc line through the decl line.
    local sym = { range = { start = { line = 0 } }, selectionRange = { start = { line = 1 } } }
    t.eq(java.is_public(buf, sym, { kind = KIND_CLASS }), true)
  end)
end)
