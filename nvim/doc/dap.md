# Debugging (nvim-dap)

Config: `lua/plugins/dap.lua`. Keymaps under `<leader>d`. Skipped under
`vim.g.no_lsp` (pager mode) for the same reason as LSP — see `doc/startup.md`.

- **Debug runs inside jdtls**: `java-debug-adapter` + `java-test` are loaded as
  *bundles into* the running jdtls server (`init_options.bundles` + `on_attach`
  `setup_dap` in `lsp/jdtls_config.lua`), not as standalone processes. No
  separate debug server; same per-project `$JAVA_HOME`. `on_attach` runs a jdtls
  resolve command, so DAP wiring must happen after attach.
- The adapter + test runner are Mason **tools** (not LSP servers), so a separate
  `mason-tool-installer` auto-installs them alongside jdtls.
- **Remote attach** uses `dap.run(...)` ad-hoc, not `dap.configurations.java`,
  because jdtls's `setup_dap_main_class_configs` overwrites `configurations.java`
  with launch-only configs on every attach. (Attach to a JVM started with JDWP,
  e.g. `./gradlew bootRun --debug-jvm`, listening on :5005.)
- dap-ui opens the scopes/stacks/breakpoints/watches/repl panels on session
  start, closes them on end. nvim-tree's window-picker excludes these panels so
  files open in the code window (see `doc/plugins.md`).

## Python

Unlike Java, Python debug is a **standalone adapter**, not a bundle in an LSP
server. `debugpy` is a mason tool (in the same `mason-tool-installer` list) and
`nvim-dap-python` (`require('dap-python').setup(...)` in `plugins/dap.lua`) is
pointed at mason's `debugpy/venv/bin/python`. That registers the `python`
adapter and default launch configs (run file / run as module / pytest). All the
`<leader>d` keymaps are language-agnostic and work as-is; remote attach
(`<leader>da`) is Java-only (JDWP).
