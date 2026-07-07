-- vim.g.no_lsp (set in init.lua when invoked as kitty's scrollback pager)
-- skips mason/lspconfig/jdtls entirely — the heaviest part of startup, and
-- pointless for a readonly scrollback dump.
local lsp_enabled = not vim.g.no_lsp

return {
  {
    'mason-org/mason.nvim',
    enabled = lsp_enabled,
    config = true,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    enabled = lsp_enabled,
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      ensure_installed = { 'jdtls' },
      -- jdtls is started manually (see lua/jdtls_config.lua) so it can use the
      -- per-project $JAVA_HOME managed by cli-assistant. Without this exclude,
      -- mason-lspconfig also auto-enables nvim-lspconfig's default jdtls config,
      -- which launches a second, conflicting client using a bare `java`/`jdtls`
      -- from PATH (ignoring JAVA_HOME) and fails with "Unable to locate a Java
      -- Runtime".
      automatic_enable = {
        exclude = { 'jdtls' },
      },
    },
  },
  { 'neovim/nvim-lspconfig', enabled = lsp_enabled },
  { 'mfussenegger/nvim-jdtls', enabled = lsp_enabled },
}
