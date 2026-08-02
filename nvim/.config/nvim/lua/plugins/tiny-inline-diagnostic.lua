---@type LazyPluginSpec
return {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = "VeryLazy",
  priority = 1000,
  opts = {
    preset = 'modern',
    options = {
      show_source = { enabled = true, if_many = true },
      show_code = true,
      multilines = { enabled = true, always_show = false },
      overflow = { mode = 'wrap' },
      show_all_diags_on_cursorline = true,
      enable_on_insert = false,
      set_arrow_to_diag_color = true,
    },
  },
}

-- return {
--   "rachartier/tiny-inline-diagnostic.nvim",
--   event= "VeryLazy",
--   priority = 1000,
--   config = function()
--     require("tiny-inline-diagnostic").setup()
--     vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
--   end,
-- }
