-- Drift guard for the command palette. The palette (command_palette.lua)
-- hardcodes the keystrokes/commands it re-sends; if a keymap is renamed or a
-- command removed without updating the palette, an entry silently sends keys
-- that map to nothing. These tests assert every palette entry still resolves.
--
-- Depends on the real config being loaded (load_spec sourced init.lua first),
-- so commands and global keymaps exist to check against.
local t = require('tests.harness')
local palette = require('features.command_palette')

-- Palette entries whose keys are LSP buffer-local (set on LspAttach), so they
-- have no global mapping to check in a headless session with no server. Listed
-- explicitly so a typo in ANY other entry still fails the drift check.
local lsp_buffer_local = {
  ['<leader>ca'] = true, -- code actions
  ['<leader>cf'] = true, -- format
  ['K'] = true, -- hover
  ['<leader>fd'] = true, -- definitions & declarations
}

-- Reads a `:Command<CR>` entry's command name, or nil if not that shape.
local function command_name(keys)
  return keys:match('^:(%u%w*)<CR>$')
end

t.describe('command palette', function()
  t.it('every entry has a desc and exactly one of keys/action', function()
    for i, def in ipairs(palette.defs) do
      t.assert(def.desc ~= nil, 'entry ' .. i .. ' has no desc')
      local has_keys = def.keys ~= nil
      local has_action = def.action ~= nil
      t.assert(has_keys ~= has_action, 'entry ' .. i .. ' must have keys XOR action')
    end
  end)

  t.it('every :Command<CR> entry references an existing command', function()
    for _, def in ipairs(palette.defs) do
      local cmd = def.keys and command_name(def.keys)
      if cmd then
        t.eq(vim.fn.exists(':' .. cmd), 2, ':' .. cmd .. ' referenced by palette does not exist')
      end
    end
  end)

  t.it('every <leader>/single-key entry maps to something (or is known LSP-local)', function()
    for _, def in ipairs(palette.defs) do
      local keys = def.keys
      -- skip action entries, ex-commands (`:...<CR>`), and built-in motions
      -- that need no mapping (splits use `:`, `-` is oil, handled below).
      if keys and not keys:match('^:') then
        if lsp_buffer_local[keys] then
          -- expected to have no global map; nothing to assert here.
        elseif keys == '-' then
          -- oil binds `-` in normal mode; assert it's actually mapped.
          t.assert(vim.fn.maparg('-', 'n') ~= '', '`-` (file explorer) is not mapped')
        else
          t.assert(vim.fn.maparg(keys, 'n') ~= '', keys .. ' maps to nothing (palette drift)')
        end
      end
    end
  end)
end)
