-- Test entry point. Run headless:
--   nvim --headless -u nvim/tests/run.lua
-- Sourced as the init, so it sets up rtp + Lua package path, then requires
-- each spec in order (load_spec must be first: it sources the real init.lua
-- and force-loads plugins the other specs depend on). harness.report() exits
-- with a non-zero code if any test failed, which `make test` propagates.
-- `:p` makes this absolute: nvim is invoked as `-u nvim/tests/run.lua` (a
-- relative path), and a relative runtimepath entry doesn't resolve for
-- nvim_get_runtime_file once lazy has reshuffled rtp.
local script = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p')
local tests_dir = vim.fn.fnamemodify(script, ':h')
local nvim_dir = vim.fn.fnamemodify(tests_dir, ':h')

_G.NVIM_TEST_DIR = nvim_dir
vim.opt.rtp:prepend(nvim_dir)
-- tests/ lives outside lua/, so add it to Lua's own search path to allow
-- `require('tests.<spec>')`.
package.path = nvim_dir .. '/?.lua;' .. nvim_dir .. '/?/init.lua;' .. package.path

local t = require('tests.harness')

local specs = {
  'tests.load_spec', -- must be first: sources init.lua, force-loads plugins
  'tests.copy_fqn_spec',
  'tests.find_method_spec',
  'tests.dispatch_spec',
  'tests.startup_spec',
  'tests.palette_spec',
}

for _, spec in ipairs(specs) do
  local ok, err = pcall(require, spec)
  if not ok then
    t.record_load_error(spec, err)
  end
end

t.report()
