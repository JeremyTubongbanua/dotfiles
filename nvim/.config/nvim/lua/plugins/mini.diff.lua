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
  -- config = function(_, opts)
  --   local diff = require('mini.diff')
  --   diff.setup(opts)

    -- gitsigns' stage_hunk/reset_hunk acted on the hunk under the cursor, or on
    -- the selection in visual mode; mini.diff's do_hunks takes a line range
    -- local function hunk(action)
    --   return function()
    --     local from, to = vim.fn.line('.'), vim.fn.line('.')
    --     if vim.fn.mode():match('^[vV\22]') then
    --       from, to = vim.fn.line('v'), vim.fn.line('.')
    --       if from > to then
    --         from, to = to, from
    --       end
    --       vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
    --     end
    --     diff.do_hunks(0, action, { line_start = from, line_end = to })
    --   end
    -- end

    -- local function map(mode, lhs, rhs, desc)
    --   vim.keymap.set(mode, lhs, rhs, { desc = desc })
    -- end

    -- -- `]c`/`[c` must stay native inside fugitive's three-way diff (<leader>gd)
    -- map('n', ']c', function()
    --   if vim.wo.diff then
    --     vim.cmd.normal({ ']c', bang = true })
    --   else
    --     diff.goto_hunk('next')
    --   end
    -- end, 'Next Git Hunk')
    --
    -- map('n', '[c', function()
    --   if vim.wo.diff then
    --     vim.cmd.normal({ '[c', bang = true })
    --   else
    --     diff.goto_hunk('prev')
    --   end
    -- end, 'Previous Git Hunk')

    -- map('n', '<leader>gph', diff.toggle_overlay, 'Preview Git Hunk')
    -- map({ 'n', 'x' }, '<leader>gsh', hunk('apply'), 'Stage Git Hunk')
    -- map({ 'n', 'x' }, '<leader>grh', hunk('reset'), 'Reset Git Hunk')
    --
    -- -- not provided by mini.diff, handed off to fugitive
    -- map('n', '<leader>guh', '<Cmd>Git<CR>', 'Git Status (u to unstage)')
    -- map('n', '<leader>gb', '<Cmd>Git blame<CR>', 'Git Blame')
    -- map('n', '<leader>gD', '<Cmd>Gvdiffsplit<CR>', 'Git Diff This')
  -- end,
}
