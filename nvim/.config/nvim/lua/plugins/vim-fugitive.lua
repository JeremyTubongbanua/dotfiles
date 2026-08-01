return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gg', ':Git<CR>', { desc = 'Git Status' })
    vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit!<CR>', { desc = 'Git Diff Split' }) -- create a three-way vertical split. Left = feature branch (//2), Middle = current file, Right = merging branch (//3)
    vim.keymap.set({ 'n', 'x' }, '<leader>gh', ':diffget //2<CR>', { desc = 'Git Diff Get Left' }) -- get changes from the left side where your cursor or selection is. Cursor must be in the middle buffer.
    vim.keymap.set({ 'n', 'x' }, '<leader>gl', ':diffget //3<CR>', { desc = 'Git Diff Get Right' }) -- get changes from the right side where your cursor or selection is. Cursor must be in the middle buffer.
    local is_fugitive = function(win)
      return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match('^fugitive://') ~= nil
    end
    vim.keymap.set('n', '<leader>gq', function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      -- If the cursor sits in a fugitive window, hop out to the working copy first
      if is_fugitive(vim.api.nvim_get_current_win()) then
        local target = nil
        for _, win in ipairs(wins) do
          if not is_fugitive(win) then
            target = target or win
            if vim.wo[win].diff then -- the working copy being diffed
              target = win
              break
            end
          end
        end
        if target then vim.api.nvim_set_current_win(target) end
      end
      local cur = vim.api.nvim_get_current_win()
      for _, win in ipairs(wins) do
        if win ~= cur and vim.api.nvim_win_is_valid(win) and is_fugitive(win) then
          vim.api.nvim_win_close(win, false) -- non-force: refuses rather than discarding unsaved edits
        end
      end
    end, { desc = 'Git Diff Quit' })
  end,
}

