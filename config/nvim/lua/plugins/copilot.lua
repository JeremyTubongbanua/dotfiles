return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup({})

    vim.keymap.set('n', '<leader>ce', ':Copilot enable<CR>', { desc = 'Enable Copilot' })
    vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { desc = 'Disable Copilot' })
  end,
}
