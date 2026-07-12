-- Provider auto-discovery: both copy_fqn and find_method scan their
-- providers/ dir at call time (no hardcoded registry). Assert the java
-- provider is found and mapped by its filetype, so adding/removing a provider
-- file is all it takes to (de)register a language.
local t = require('tests.harness')

for _, mod in ipairs({ 'features.copy_fqn', 'features.find_method' }) do
  t.describe(mod .. ' provider discovery', function()
    local by_ft = require(mod)._providers_by_filetype()

    t.it('discovers the java provider by filetype', function()
      t.assert(by_ft['java'] ~= nil, 'no provider mapped for filetype java')
      t.eq(by_ft['java'].name, 'java')
    end)

    t.it('has no provider for an unregistered filetype', function()
      t.eq(by_ft['ruby'], nil)
    end)
  end)
end
