---@type LazyPluginSpec
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup({
      copilot_node_command = { 'node', '--no-warnings' },
    })

    local copilot_command = require('copilot.command')
    local copilot_client = require('copilot.client')
    local enable_copilot = copilot_command.enable
    local disable_copilot = copilot_command.disable
    local enabled = true

    copilot_command.enable = function()
      if enabled then
        if #vim.lsp.get_clients({ name = 'copilot' }) == 0 then
          copilot_client.ensure_client_started()
        end
        return
      end

      enabled = true
      enable_copilot()
    end

    copilot_command.disable = function()
      enabled = false
      disable_copilot()
    end

    vim.keymap.set('n', '<leader>ce', ':Copilot enable<CR>', { desc = 'Enable Copilot' })
    vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { desc = 'Disable Copilot' })
  end,
}
