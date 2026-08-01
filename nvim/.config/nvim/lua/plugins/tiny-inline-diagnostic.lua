-- Renders the full LSP diagnostic message inline in the buffer, under the cursor
-- line. Replaces Neovim's built-in virtual_text, which appends the message to the
-- end of the line and truncates long TypeScript errors -- so `virtual_text` is set
-- to false in lsp.lua and this plugin owns that display. Without that, both render
-- and you see the message twice.
--
-- Severity colours come from `hi` below, which points at the stock Diagnostic*
-- groups -- including the brightened DiagnosticError set in lsp.lua, so the inline
-- text picks up the same bright red automatically.
return {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = 'LspAttach',
  opts = {
    preset = 'modern',
    options = {
      -- label the server when ts_ls and eslint both report on one line
      show_source = { enabled = true, if_many = true },
      -- keep the TS error code (e.g. ts(2322)) -- useful for searching
      show_code = true,
      -- TypeScript errors are long: wrap onto extra lines rather than cutting off,
      -- but only for the line the cursor is on (always_show would do every line)
      multilines = { enabled = true, always_show = false },
      overflow = { mode = 'wrap' },
      -- if one line has two errors, show both instead of only the first
      show_all_diags_on_cursorline = true,
      -- don't redraw diagnostics while typing
      enable_on_insert = false,
      -- tint the arrow to the severity colour so an error reads red end-to-end
      set_arrow_to_diag_color = true,
    },
  },
}
