return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require('catppuccin').setup({
      flavour = "mocha",
      custom_highlights = function(colors)
        return {
          -- Example custom overrides for fugitive/diff blocks
          fugitiveHash = { fg = colors.yellow },
          fugitiveHeader = { fg = colors.mauve, style = { "bold" } },
          fugitiveStagedHeading = { fg = colors.green, style = { "bold" } },
          fugitiveUnstagedHeading = { fg = colors.red, style = { "bold" } },

          -- Standard diff views inside fugitive status/commit buffers
          diffAdded = { fg = colors.green },
          diffRemoved = { fg = colors.red },
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin')
  end,
}
