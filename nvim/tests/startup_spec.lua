local t = require('tests.harness')
local pager = require('util.pager')

t.describe('util.pager kitty-pager detection', function()
  t.it('true when argv invokes the kitty pager module', function()
    t.eq(pager.is_pager_argv({ 'nvim', '-c', "lua require('util.kitty_pager')(0, 1, 1)" }), true)
  end)

  t.it('false for a normal file-open invocation', function()
    t.eq(pager.is_pager_argv({ 'nvim', 'Foo.java' }), false)
  end)

  t.it('false for an empty argv', function()
    t.eq(pager.is_pager_argv({}), false)
  end)
end)
