-- https://github.com/folke/flash.nvim
---@type LazyPluginSpec
return {
  'folke/flash.nvim',
  config = function()
    require('flash').setup({})
  end,
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
}

