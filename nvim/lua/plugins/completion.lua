return {
  'saghen/blink.cmp',
  version = '1.*',
  opts = {
    keymap = {
      preset = 'default',
      ['<Tab>'] = { 'accept', 'fallback' },
      ['<Esc>'] = { 'hide', 'fallback' },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
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
