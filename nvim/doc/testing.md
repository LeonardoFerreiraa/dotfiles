# Testing

Headless Neovim test suite under `nvim/tests/`. No external deps — a tiny
harness (`tests/harness.lua`) with `describe`/`it`/`assert`, run by
`tests/run.lua`, which exits non-zero on any failure.

## Running

- `make test` — runs the suite (`nvim --headless -u nvim/tests/run.lua`).
- `make hooks` — installs the git pre-push hook (`core.hooksPath=.githooks`), so
  `git push` runs `make test` first. Bypass a one-off with `git push --no-verify`.

## How it's wired

- `run.lua` sets up rtp + Lua `package.path` (absolute — a relative rtp entry
  doesn't resolve for `nvim_get_runtime_file` after lazy reshuffles rtp), then
  requires each spec in order.
- `load_spec` must run **first**: it sources the real `init.lua` (true e2e
  startup ordering) and force-loads telescope/plenary (they load on
  VeryLazy/on-demand, which never fires headless) so later specs' deps resolve.
- Specs register tests at require time; `harness.report()` prints a summary and
  exits.

## What's covered

- `load_spec` — real config sources without error; user commands + global
  keymaps + leader present.
- `palette_spec` — command-palette drift: every entry resolves to a real
  keymap/command (LSP buffer-local keys are an explicit allowlist).
- `copy_fqn_spec` / `find_method_spec` — pure provider logic (FQN rendering,
  visibility, signature cleanup) against fabricated buffers.
- `dispatch_spec` — provider auto-discovery by filetype.
- `startup_spec` — `util.pager` kitty-pager argv detection.

## Adding tests

New load-bearing invariant? Prefer a test over a doc note when it's cheap to
assert. Expose test-only hooks as `M._name` (see `copy_fqn/init.lua`). Add the
spec to the `specs` list in `run.lua`.
