local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')
local file_ops = require('file_ops')

-- desc pode ser uma string ou uma lista de strings (sinônimos/aliases) —
-- cada desc vira uma linha própria na palette, todas com o mesmo `keys`.
-- Um item pode usar `keys` (reenviado via feedkeys) OU `action` (função Lua,
-- pra ações que precisam de input do usuário, como criar/renomear arquivo).
local defs = {
  -- find / telescope
  { keys = '<leader>ff', desc = { 'go to file', 'find file' } },
  { keys = '<leader>fg', desc = { 'live grep', 'find anywhere' } },
  { keys = '<leader>fb', desc = { 'find buffers', 'open buffers' } },
  { keys = '<leader>fw', desc = 'find warnings erros' },
  { keys = '<leader>fu', desc = 'find usage' },
  { keys = '<leader>fd', desc = { 'go to definitions', 'go to declarations' } },

  -- lsp
  { keys = '<leader>ca',      desc = 'code actions' },
  { keys = '<leader>cf',      desc = 'format document' },
  { keys = '<leader>sd',      desc = 'show diagnostic' },
  { keys = 'K',               desc = 'show documentation' },
  { keys = '<leader>l',       desc = 'clean highlight' },
  { keys = ':FindMethod<CR>', desc = 'find method' },
  { keys = ':CopyFQN<CR>',    desc = 'copy fqn' },

  -- jumps
  { keys = '<leader>gb', desc = 'go back' },
  { keys = '<leader>gf', desc = 'go forward' },

  -- window navigation
  { keys = '<leader>nh', desc = 'go to left window' },
  { keys = '<leader>nj', desc = 'go to lower window' },
  { keys = '<leader>nk', desc = 'go to upper window' },
  { keys = '<leader>nl', desc = 'go to right window' },

  -- splits / explorer
  { keys = '-',                      desc = 'open file explorer' },
  { keys = ':split<CR>',             desc = 'split up' },
  { keys = ':rightbelow split<CR>',  desc = 'split down' },
  { keys = ':vsplit<CR>',            desc = 'split left' },
  { keys = ':rightbelow vsplit<CR>', desc = 'split right' },

  -- buffers
  { keys = ':CloseOtherBuffers<CR>', desc = 'close other buffers' },

  -- file operations
  { action = file_ops.create_file, desc = 'create file' },
  { action = file_ops.rename_file, desc = 'rename file' },
  { action = file_ops.delete_file, desc = 'delete file' },
}

-- Flattens `defs` (which may have multiple descs per entry) into one
-- picker item per desc string.
local function build_items(definitions)
  local items = {}
  for _, def in ipairs(definitions) do
    local descs = type(def.desc) == 'table' and def.desc or { def.desc }
    for _, desc in ipairs(descs) do
      table.insert(items, { keys = def.keys, action = def.action, desc = desc })
    end
  end
  return items
end

local function build_displayer(items)
  local max_desc_len = 0
  for _, item in ipairs(items) do
    max_desc_len = math.max(max_desc_len, #item.desc)
  end
  return entry_display.create({
    separator = '  ',
    items = {
      { width = max_desc_len },
      { remaining = true },
    },
  })
end

local M = {}

function M.open()
  local items = build_items(defs)
  local displayer = build_displayer(items)
  local function make_display(entry)
    return displayer({
      entry.desc,
      { entry.keys or '', 'Comment' },
    })
  end

  pickers.new({}, {
    prompt_title = 'Command Palette',
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          desc = entry.desc,
          keys = entry.keys,
          action = entry.action,
          display = make_display,
          ordinal = entry.desc,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection.value.action then
          selection.value.action()
        else
          local keys = vim.api.nvim_replace_termcodes(selection.value.keys, true, false, true)
          vim.api.nvim_feedkeys(keys, 'm', false)
        end
      end)
      return true
    end,
  }):find()
end

return M
