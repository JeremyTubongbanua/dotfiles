-- theme
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require('catppuccin').setup({
      -- follow the terminal's light/dark mode; latte is catppuccin's only light flavour
      flavour = "auto",
      background = { light = "latte", dark = "mocha" },
      integrations = {
        native_lsp = {
          -- catppuccin defaults every severity to a flat `underline`
          underlines = { errors = { "undercurl" } },
        },
      },
      custom_highlights = function(colors)
        return {
          -- catppuccin gives DiagnosticUnderlineError an `sp` but no `fg`, so the
          -- erroring token keeps its syntax colour and the error reads as dim.
          DiagnosticUnderlineError = { fg = colors.red, sp = colors.red, undercurl = true },

          -- in diff buffers catppuccin makes diffAdded/diffRemoved fg-only, so
          -- added/removed lines read as coloured text. tokyonight instead gives
          -- them DiffAdd/DiffDelete's background, so whole lines get a green/red
          -- wash like a highlighter. catppuccin already defines those
          -- backgrounds, so just re-link. The `@diff.*` treesitter captures
          -- follow along, since catppuccin links them to these three groups.
          diffAdded = { link = "DiffAdd" },
          diffRemoved = { link = "DiffDelete" },
          diffChanged = { link = "DiffChange" },
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin-nvim')
  end,
}
