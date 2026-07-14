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
      ensure_installed = { 'jdtls', 'basedpyright', 'ruff' },
      automatic_enable = {
        exclude = { 'jdtls' },
      },
    },
  },
  { 'neovim/nvim-lspconfig', enabled = lsp_enabled },
  { 'mfussenegger/nvim-jdtls', enabled = lsp_enabled },
}
