-- theme
return {
  "folke/tokyonight.nvim",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000,
  opts = {},
  config = function()
    -- require('tokyonight').setup({})
    -- vim.cmd.colorscheme('tokyonight-night')
  end,
}
