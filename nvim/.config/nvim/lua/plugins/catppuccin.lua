-- theme
---@type LazyPluginSpec
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require('catppuccin').setup({
      flavour = "auto",
      background = {
        light = "latte", dark = "mocha"
      },
      integrations = {
        native_lsp = {
          underlines = {
            errors = {
              "undercurl"
            }
          },
        },
      },
      custom_highlights = function(colors)
        return {
          DiagnosticUnderlineError = {
            fg = colors.red,
            sp = colors.red,
            undercurl = true,
          },
          diffAdded = {
            link = "DiffAdd"
          },
          diffRemoved = {
            link = "DiffDelete"
          },
          diffChanged = {
            link = "DiffChange"
          },
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin-nvim')
  end,
}
