---@type LazyPluginSpec
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "auto",
    background = {
      light = "latte",
      dark = "macchiato"
    },
    integrations = {
      native_lsp = {
        flash = true,
        harpoon = false,
        underlines = {
          errors = {
            "undercurl"
          }
        },
      },
    },
    mason = false,
    mini = {
      enabled = true,
      indentscope_color = "",
    },
    treesitter_context = true,
    snacks = {
      enabled = false,
      indent_scope_color = "", -- catppuccin color (eg. `lavender`) Default: overlay2
    },
    which_key = false,
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
  },
}
