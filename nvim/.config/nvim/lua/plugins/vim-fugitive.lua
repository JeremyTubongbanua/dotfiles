return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gg', ':Git<CR>', { desc = 'Git Status' })

    -- For reserving merge conflicts
    vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit!<CR>', { desc = 'Git Diff Split' }) -- Create a three-way vertical split. Left = feature branch (//2), Middle = current file, Right = merging branch (//3)
    vim.keymap.set({ 'n', 'x' }, '<leader>gh', ':diffget //2<CR>', { desc = 'Git Diff Get Left' }) -- Get changes from the left side where your cursor or selection is. Cursor must be in the middle buffer.
    vim.keymap.set({ 'n', 'x' }, '<leader>gl', ':diffget //3<CR>', { desc = 'Git Diff Get Right' }) -- Get changes from the right side where your cursor or selection is. Cursor must be in the middle buffer.
  end,
}

