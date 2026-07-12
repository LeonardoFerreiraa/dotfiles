NVIM ?= nvim

.PHONY: test hooks

# Headless Neovim test suite (nvim/tests). Sources the real config, runs the
# specs, exits non-zero on any failure. See nvim/tests/run.lua.
test:
	$(NVIM) --headless -u nvim/tests/run.lua

# Point git at the versioned hooks dir so `git push` runs `make test` first.
# Run once after cloning: `make hooks`.
hooks:
	git config core.hooksPath .githooks
	@echo "git hooks installed (core.hooksPath=.githooks)"
