-- https://github.com/folke/flash.nvim
---@type LazyPluginSpec
return {
  'folke/flash.nvim',
  event = "VeryLazy",
  opts = {
    modes = {
      char = { -- `f'` then keep pressing `f` to hop between matches (`F` to go back)
        enabled = true,
      },
    },
  },
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
}

