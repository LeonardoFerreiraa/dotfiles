# Features & LSP helpers

Custom modules under `lua/features/` and `lua/lsp/`.

## Command palette (`features/command_palette.lua`)

Telescope picker listing keybindings/commands with descriptions; picking one
re-sends its keystrokes (or runs a Lua `action`, for file create/rename/delete).

It **hardcodes** the keystrokes/commands it re-sends. `tests/palette_spec.lua`
asserts every entry still resolves to a real keymap/command — if you rename a
map or drop a command, update the palette or the test fails. Add a palette entry
only for a binding that actually exists.

## Providers (`copy_fqn`, `find_method`)

Each is `init.lua` (filetype -> provider dispatch, auto-discovered from
`providers/*.lua`) + `engine.lua` (language-agnostic logic) + `providers/<lang>.lua`.
See `doc/architecture.md` for the discovery contract.

- **copy_fqn** — IntelliJ's "Copy Reference": renders the DocumentSymbol path
  under the cursor as `pkg.Outer.Inner#member` and copies it. Java format tested
  in `tests/copy_fqn_spec.lua`.
- **find_method** — workspace/symbol to list classes, documentSymbol to
  enumerate a class's public members, hover for signatures, jump to the pick.
  - Non-`file://` uris (jdtls's `jdt://` library/JDK sources) are opened via the
    server's own `BufReadCmd`.
  - Generic type params are stripped (`HashMap<K,V>` -> `HashMap`) so
    `documentSymbol` and `workspace/symbol` names compare equal.
  - Visibility/signature cleanup is per-provider; Java logic tested in
    `tests/find_method_spec.lua`.

## Instant-feedback pickers

`lsp_extras`, `find_method`, and `command_palette` open Telescope **immediately**
with a loading placeholder (`util/telescope_loading`), then refresh
asynchronously once the LSP responds — so a keypress gives instant feedback
instead of a 1-2s stall on slow servers like jdtls.

## workspace_undo (`lsp/workspace_undo.lua`)

Wraps `vim.lsp.util.apply_workspace_edit` to record which buffers a multi-file
edit touched, so `u` (`smart_undo`, bound in `config/lsp`) rolls a
rename/refactor back across every file at once. A buffer edited again after the
workspace edit is skipped (its undo position no longer matches) instead of
clobbering later edits.

## hover_box (`lsp/hover_box.lua`)

Overrides `vim.lsp.util.open_floating_preview` for `K` — rounded border, inner
padding, a blank line after a leading signature fence (jdtls renders signature +
Javadoc with no gap), `<Esc>` to dismiss, and auto-focus into the float.
