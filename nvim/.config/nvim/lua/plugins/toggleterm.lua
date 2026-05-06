-- https://github.com/akinsho/toggleterm.nvim
-- To toggle terminal in nvim
return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require("toggleterm").setup({
      size = 20,
      direction = 'horizontal',
      start_in_insert = false, -- start in normal mode when opening terminal
    })
    vim.keymap.set('n', '<C-/>', ':ToggleTerm<CR>', { desc = "Toggle Terminal" }) -- toggles terminal and selects it and goes into terminal mode
    vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], { desc = "Exit Terminal Mode + Window Command" }) -- leaves terminal mdoe (C-\ and C-n) then does the usual C-w
  end,
}
