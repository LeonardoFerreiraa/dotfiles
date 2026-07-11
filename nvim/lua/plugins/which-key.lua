return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    -- show immediately (default waits ~500ms) so a <leader> prefix that
    -- goes nowhere (typo'd first key) is confirmed right away instead of
    -- after a pause.
    delay = 0,
    win = {
      border = 'rounded',
      -- centered instead of the default bottom-anchored popup.
      row = 0.5,
      col = 0.5,
      -- without a cap, the popup spreads its key hints across multiple
      -- columns to fill the whole screen width; this narrows it so entries
      -- stack in fewer, taller columns instead.
      width = 0.3,
    },
  },
}
