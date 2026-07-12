# Neovim config

The Lua source is deliberately **comment-free**. Load-bearing "why" lives in
`doc/` (read the relevant file on demand) or as a test — never as inline
comments (they rot because they get ignored). When you change behaviour, update
the matching doc and/or a test.

Before pushing: `make test` (a pre-push hook runs it too; `make hooks` installs).

## Docs — open the one that matches your task

- `doc/architecture.md` — layout, where new code goes, conventions (keymap
  namespaces, provider auto-discovery, test hooks, no-comments policy).
- `doc/startup.md` — `init.lua` ordering invariants (leader→lazy, netrw, jdtls
  autocmd, pager mode / `vim.g.no_lsp`, folding).
- `doc/jdtls.md` — Java/jdtls: cli-assistant `$JAVA_HOME`, the double-client
  exclude, metadata-files JVM prop, formatter-XML-vs-indentation.
- `doc/dap.md` — debugging: bundles loaded into jdtls, remote attach.
- `doc/features.md` — command palette (drift test), copy_fqn / find_method
  providers, loading-placeholder pickers, workspace_undo, hover_box.
- `doc/plugins.md` — nvim-tree (the file browser, not oil), telescope + ripgrep
  flags.
- `doc/testing.md` — the headless test suite: running, wiring, coverage, how to
  add tests.
