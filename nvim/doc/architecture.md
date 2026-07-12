# Architecture

## Layout

```
init.lua              bootstrap lazy, set leader, load config, detect pager, load plugins/lsp
lua/config/           options, keymaps (global maps), lsp (LSP/jdtls autocmds, user commands, LspAttach maps)
lua/plugins/          one file per plugin, each returns a lazy spec
lua/lsp/              jdtls_config, lsp_extras, hover_box, workspace_undo
lua/features/         command_palette, copy_fqn/, find_method/
lua/util/             file_ops, buffers, fold_text, telescope_loading, kitty_pager, pager
lua/features/<x>/     init.lua (filetype -> provider dispatch) + engine.lua (logic) + providers/<lang>.lua
tests/                headless test suite (see run.lua, and doc/testing.md)
codestyle/            eclipse-profile.xml (jdtls formatter base profile)
```

## Where new code goes

- global keymap -> `config/keymaps`
- LSP buffer-local keymap -> `config/lsp` (LspAttach)
- plugin-specific keymap -> that plugin's file
- pure helper -> `util/`
- LSP-facing helper -> `lsp/`
- user-facing feature -> `features/`

## Conventions

- **Keymap namespaces** under `<leader>` (space): `g`=go/jump, `n`=window nav,
  `s`=show, `c`=code, `f`=find, `l`=clear highlight, `d`=debug. Keep new maps in
  their namespace so which-key / the command palette stay legible.
- **Language providers** (`copy_fqn`, `find_method`) are auto-discovered from
  `providers/*.lua` at call time — no registry. Add a language by dropping
  `providers/<name>.lua` returning `{ name, filetypes, client_name, ... }`.
  A provider that fails to load is silently skipped (pcall), so a typo means the
  language just goes missing — `tests/dispatch_spec.lua` guards discovery.
- **Test hooks**: modules expose `M._something` / `M.defs` *only* for tests.
  Not part of the runtime API.
- **No inline comments**: the Lua source is deliberately comment-free.
  Load-bearing "why" lives in `doc/` (read on demand) or as a test — never as a
  comment (they rot because they get ignored). Changing behaviour means updating
  a doc and/or a test, not adding a comment.
