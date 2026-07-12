-- End-to-end load test: sources the REAL init.lua the same way Neovim would,
-- so it exercises the actual startup ordering (leader before lazy, jdtls via
-- FileType autocmd, config.lsp wiring). Catches the class of regression where
-- reordering or renaming a require breaks startup — the thing most likely to
-- go wrong when refactoring the tree.
local t = require('tests.harness')
local nvim_dir = _G.NVIM_TEST_DIR

t.describe('config load', function()
  t.it('init.lua sources without error', function()
    local ok, err = pcall(dofile, nvim_dir .. '/init.lua')
    t.assert(ok, 'init.lua errored: ' .. tostring(err))
  end)

  -- Force-load the plugins the custom modules depend on. Under lazy these
  -- load on VeryLazy/on-demand, which never fires in headless; without this,
  -- requiring command_palette (telescope at module top) would fail.
  pcall(function()
    require('lazy').load({ plugins = { 'telescope.nvim', 'plenary.nvim' } })
  end)

  -- User commands defined at load time (not the buffer-local java ones).
  for _, cmd in ipairs({ 'FindMethod', 'CopyFQN', 'CloseOtherBuffers' }) do
    t.it(':' .. cmd .. ' command exists', function()
      t.eq(vim.fn.exists(':' .. cmd), 2, cmd .. ' not registered')
    end)
  end

  -- A sample of global keymaps that are set at load (not on LspAttach), one
  -- per config source so a wholesale load failure of any is caught.
  local global_maps = {
    ['<leader>l'] = 'config.keymaps',
    ['<leader>nh'] = 'config.keymaps',
    ['<leader>sd'] = 'config.lsp',
  }
  for lhs, src in pairs(global_maps) do
    t.it('normal-mode map ' .. lhs .. ' set (' .. src .. ')', function()
      t.assert(vim.fn.maparg(lhs, 'n') ~= '', lhs .. ' not mapped')
    end)
  end

  t.it('mapleader is space', function()
    t.eq(vim.g.mapleader, ' ')
  end)
end)
