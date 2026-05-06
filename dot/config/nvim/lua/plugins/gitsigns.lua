return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    signcolumn = true,
    numhl = true,
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gitsigns.nav_hunk('next')
        end
      end, 'Next Git Hunk')

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gitsigns.nav_hunk('prev')
        end
      end, 'Previous Git Hunk')

      map('n', '<leader>gph', gitsigns.preview_hunk_inline, 'Preview Git Hunk')
      map('n', '<leader>gsh', gitsigns.stage_hunk, 'Stage Git Hunk')
      map({ 'n', 'v' }, '<leader>grh', gitsigns.reset_hunk, 'Reset Git Hunk')
      map('n', '<leader>guh', gitsigns.undo_stage_hunk, 'Undo Stage Git Hunk')
      map('n', '<leader>gb', gitsigns.blame_line, 'Git Blame Line')
      map('n', '<leader>gB', gitsigns.toggle_current_line_blame, 'Toggle Git Blame')
      map('n', '<leader>gD', gitsigns.diffthis, 'Git Diff This')
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Git Hunk')
    end,
  },
}
