return {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = 'LspAttach',
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
