-- Tiny test harness. No external deps: specs `require` this, call
-- describe/it/assert, and tests run immediately at require time. run.lua
-- requires each spec in order, then calls report() which prints a summary
-- and exits the headless nvim with a non-zero code if anything failed.
local M = { failures = {}, passed = 0, _group = nil }

function M.describe(name, fn)
  local prev = M._group
  M._group = (prev and prev .. ' › ' or '') .. name
  fn()
  M._group = prev
end

function M.it(name, fn)
  local label = (M._group and M._group .. ' › ' or '') .. name
  local ok, err = pcall(fn)
  if ok then
    M.passed = M.passed + 1
  else
    table.insert(M.failures, { name = label, err = tostring(err) })
  end
end

-- Records a spec file that blew up on require (e.g. syntax error), so a
-- broken spec is reported as a failure instead of silently skipped.
function M.record_load_error(spec, err)
  table.insert(M.failures, { name = 'load ' .. spec, err = tostring(err) })
end

function M.assert(cond, msg)
  if not cond then
    error(msg or 'assertion failed', 2)
  end
end

function M.eq(got, want, msg)
  if got ~= want then
    error((msg and msg .. ': ' or '') .. 'expected ' .. vim.inspect(want) .. ', got ' .. vim.inspect(got), 2)
  end
end

function M.report()
  local total = M.passed + #M.failures
  io.write('\n')
  for _, f in ipairs(M.failures) do
    io.write('FAIL  ' .. f.name .. '\n      ' .. f.err:gsub('\n', '\n      ') .. '\n')
  end
  io.write(string.format('\n%d/%d passed, %d failed\n', M.passed, total, #M.failures))
  vim.cmd('qa!') -- fallback
  os.exit(#M.failures == 0 and 0 or 1)
end

return M
