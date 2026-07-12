# jdtls / Java

Config: `lua/lsp/jdtls_config.lua`. Started from a `FileType java` autocmd in
`config/lsp` (see `doc/startup.md` for why not ftplugin).

## cli-assistant (external dependency)

The JDK is managed per-project by cli-assistant
(`~/.local/libexec/cli-assistant/cli-assistant`), which sets `$JAVA_HOME` from
the cwd. jdtls launches with that `$JAVA_HOME` instead of a hardcoded JDK path.

- `:JavaSetJdk` — pick a JDK via cli-assistant and (re)start jdtls. Useful when
  nvim was opened from a dir with no JDK selected, so jdtls never started.
- `:JavaReindex` — wipe the jdtls workspace data and restart (full re-index).
  Useful after switching JDKs mid-session or a corrupted index.

## Gotchas (an LLM will "clean these up" and break them)

- **jdtls double-client**: `plugins/lsp.lua` sets mason-lspconfig
  `automatic_enable.exclude = { 'jdtls' }`. Otherwise nvim-lspconfig auto-starts
  a *second* jdtls using a bare `java`/`jdtls` from PATH (ignoring `$JAVA_HOME`)
  and fails with "Unable to locate a Java Runtime". jdtls is started manually so
  it uses the per-project `$JAVA_HOME`.
- **Metadata files out of project root**: launched with the JVM prop
  `-Djava.import.generatesMetadataFilesAtProjectRoot=false` (keeps
  `.project`/`.classpath`/`.settings` in the workspace dir, IntelliJ-style). The
  `settings.java.import.*` key equivalent is unreliable
  (redhat-developer/vscode-java#2929); the JVM system-property form is honored.
- **Formatter XML vs indentation**: the Eclipse profile
  (`codestyle/eclipse-profile.xml`) controls codestyle (braces, wrapping, import
  order) but **not** indentation. The LSP formatting request always carries
  `tabSize`/`insertSpaces` derived from the buffer's `shiftwidth`/`expandtab`,
  and jdtls prioritizes those over the XML's `tabulation.*` keys. So indentation
  is applied as buffer-local vim options from the XML's `tabulation.size`/`char`
  — unless the buffer has a resolved `.editorconfig` (that wins). The XML's
  tabulation settings are a dead letter; don't fight them.

Debug integration (bundles loaded into jdtls) is covered in `doc/dap.md`.
