# Plugin notes

One file per plugin in `lua/plugins/`, each returning a lazy spec.

## File browser: nvim-tree (NOT oil)

The directory browser is **nvim-tree**, not oil — there is no oil.nvim
installed. Ignore any stale "oil" reference you find in the tree.

- `-` opens the floating tree and reveals (cursor on) the current file,
  mimicking netrw's `-`.
- `<Esc><Esc>` closes it (matches Telescope's dismiss).
- netrw is disabled so `nvim <dir>` / `:edit <dir>` render the tree in the
  current window (full-window, netrw-style), not a side panel.
- **Window-picker excludes dap-ui panels + terminal buffers**: during a debug
  session dap-ui opens several windows; without the exclude, nvim-tree prompts
  "pick a window" when opening a file. Excluding them makes the file open
  directly in the code window.

## Telescope + ripgrep

`live_grep`/`find_files` pass:

- `--follow` — follow symlinks (needed for `~/v-workspace`, a tree of symlinks
  to real repos; rg ignores them otherwise).
- `--no-require-git` — honor `.gitignore`/`.ignore` even without a `.git`, so
  `build/` and `*.class` don't leak into results (rg's default `--require-git`
  skips ignore files when there's no `.git`).

Layout: prompt at the top, results top-down; directory segments shortened (Java
packages like `br/com/pagbank/watchdog/...`) with the filename kept untruncated;
long result lines wrapped instead of cut off.
