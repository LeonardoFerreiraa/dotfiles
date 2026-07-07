return {
  'saghen/blink.cmp',
  version = '1.*',
  opts = {
    keymap = {
      -- default preset: <C-space> opens the menu (and toggles docs),
      -- <C-n>/<C-p> and <Up>/<Down> select, <C-e> hides.
      preset = 'default',
      -- accept the selected item with <Tab> (falls through to normal
      -- <Tab> behaviour when the completion menu is not open).
      ['<Tab>'] = { 'accept', 'fallback' },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        -- jdtls (and some other servers) return completion lists flagged
        -- `isIncomplete = true` and then re-filter server-side by *prefix* on
        -- every keystroke. That means typing `input` after `socket.` makes
        -- jdtls return nothing (no member *starts with* "input"), so
        -- `getInputStream` never reaches the client. We force every LSP
        -- response to be treated as complete: blink then caches the full
        -- member list from the `.` trigger and does its own Rust fuzzy
        -- matching locally, where a substring like "input" correctly matches
        -- "getInputStream".
        lsp = {
          override = {
            get_completions = function(self, ctx, cb)
              return self:get_completions(ctx, function(response)
                response.is_incomplete_forward = false
                response.is_incomplete_backward = false
                cb(response)
              end)
            end,
          },
        },
      },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
}
