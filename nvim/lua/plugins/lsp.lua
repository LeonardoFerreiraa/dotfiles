return {
  {
    'mason-org/mason.nvim',
    config = true,
  },
  {
    'mason-org/mason-lspconfig.nvim',
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
  'neovim/nvim-lspconfig',
  'mfussenegger/nvim-jdtls',
}
