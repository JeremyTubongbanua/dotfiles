-- theme
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000,
  config = function()
    require('catppuccin').setup({
      flavour = "mocha",
    })
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
