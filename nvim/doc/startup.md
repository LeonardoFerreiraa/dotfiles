# Startup invariants

Ordering in `init.lua` matters — don't reorder these.

- `mapleader` is set (in `config/keymaps`) **before** `lazy.setup()`. Lazy
  expands `<leader>` in plugin `keys` specs at load time; a later leader is
  ignored for those.
- netrw is disabled (`vim.g.loaded_netrw*` in `config/options`) **before** the
  netrw plugin loads at startup. nvim-tree is the directory browser (see
  `doc/plugins.md`).
- jdtls is started from a `FileType java` autocmd in `config/lsp`, **not**
  `ftplugin/java.lua`. ftplugin runs before lazy finishes putting plugins on the
  runtimepath, so `nvim Foo.java` opened directly would fail with
  "module 'jdtls' not found".
- `config/lsp` is required **after** `lazy.setup()` so plugins are on the rtp and
  Neovim's default LSP maps (e.g. `gra`, `<C-w>d`) exist to be unmapped.
- Folding is a global `foldexpr = vim.lsp.foldexpr()`; it degrades to "no folds"
  on buffers with no LSP client, so it's safe as a default.

## Pager mode

`util/pager.is_pager_argv(vim.v.argv)` sets `vim.g.no_lsp` when Neovim is invoked
as kitty's `scrollback_pager` (argv contains the string `kitty_pager`, see
`kitty/kitty.conf`). That skips mason/lspconfig/jdtls (`plugins/lsp.lua`,
`plugins/dap.lua`) and `config/lsp` — heavy and pointless for a readonly
scrollback dump.

If you rename the `kitty_pager` module, update **both** the argv substring in
`util/pager.lua` and `kitty/kitty.conf`.

Gotcha when testing headless: any `-c "lua ..."` argument that contains the
string `kitty_pager` (e.g. `require('util.kitty_pager')`) trips this detection
and sets `no_lsp=true`, so `:CopyFQN`/`:FindMethod` won't be registered. It's the
detector working, not a bug.
