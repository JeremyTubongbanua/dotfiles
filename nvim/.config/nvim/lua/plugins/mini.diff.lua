-- inline git diff signs -- https://github.com/echasnovski/mini.diff
-- replaces gitsigns.nvim. mini.diff has no blame / unstage-hunk / diffthis, so
-- those three keymaps now go through vim-fugitive instead.
return {
  'echasnovski/mini.diff',
  version = false,
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    -- gitsigns drew both signs and number highlights; mini.diff does one or the
    -- other, so keep the sign column and use gitsigns' glyphs
    -- view = {
    --   style = 'sign',
    --   signs = {
    --     add = '┃',
    --     change = '┃',
    --     delete = '▁'
    --   },
    -- },
    -- mini.diff's own gh/gH/[h/]h/[H/]H are disabled to keep the gitsigns
    -- keymap surface; the equivalents are mapped by hand in `config` below
    mappings = {
      apply = '',
      reset = '',
      textobject = 'ih',
      goto_first = '',
      goto_prev = '',
      goto_next = '',
      goto_last = '',
    },
  },
}
