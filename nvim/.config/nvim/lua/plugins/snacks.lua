return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    animate = { enabled = true },
    bigfile = { enabled = true },
    -- bufdelete = { enabled = true },
    dashboard = { enabled = true },
    debug = { enabled = true },
    -- explorer = { enabled = true },
    image = {
      enabled = true,
      doc = {
        enabled = false, -- Disable inline rendering in markdown/documents
      },
    }, -- brew install imagemagick ghostscript
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        -- `hidden` shows this repo's dotted dirs (nvim/.config/...); snacks'
        -- rg/fd/find commands already prune .git, so only .jj needs excluding
        files = { hidden = true, exclude = { ".jj" } },
        grep = { hidden = true, exclude = { ".jj" } },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    -- windows = { enabled = true },
    -- words = { enabled = true },
    -- zen = { enabled = true },
  },
  keys = {
    { "<leader><leader>", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live Grep" },
  },
}
