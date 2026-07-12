local M = {}

local function range_contains(r, pos)
  local after_start = pos.line > r.start.line or (pos.line == r.start.line and pos.character >= r.start.character)
  local before_end = pos.line < r['end'].line or (pos.line == r['end'].line and pos.character <= r['end'].character)
  return after_start and before_end
end

local function symbol_path(symbols, pos)
  for _, sym in ipairs(symbols or {}) do
    if sym.range and range_contains(sym.range, pos) then
      local path = { sym }
      vim.list_extend(path, symbol_path(sym.children, pos))
      return path
    end
  end
  return {}
end

function M.run(provider)
  local bufnr = vim.api.nvim_get_current_buf()
  local winnr = vim.api.nvim_get_current_win()

  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/documentSymbol' })
  if provider.client_name then
    clients = vim.tbl_filter(function(c)
      return c.name == provider.client_name
    end, clients)
  end
  local client = clients[1]
  if not client then
    vim.notify(
      'CopyFQN: nenhum LSP (' .. (provider.client_name or 'com documentSymbol') .. ') anexado a este buffer.',
      vim.log.levels.WARN
    )
    return
  end

  local params = vim.lsp.util.make_position_params(winnr, client.offset_encoding)
  local request_params = { textDocument = params.textDocument }

  client:request('textDocument/documentSymbol', request_params, function(err, result)
    if err or not result or #result == 0 then
      vim.notify('CopyFQN: falha ao obter símbolos.', vim.log.levels.ERROR)
      return
    end

    local path = symbol_path(result, params.position)
    if #path == 0 then
      vim.notify('CopyFQN: nenhum símbolo sob o cursor.', vim.log.levels.WARN)
      return
    end

    local fqn = provider.build_fqn(bufnr, path)
    if not fqn or fqn == '' then
      vim.notify('CopyFQN: provider não conseguiu montar o FQN.', vim.log.levels.ERROR)
      return
    end

    vim.fn.setreg('+', fqn)
    vim.fn.setreg('"', fqn)
    vim.notify('FQN copiado: ' .. fqn, vim.log.levels.INFO)
  end, bufnr)
end

return M
