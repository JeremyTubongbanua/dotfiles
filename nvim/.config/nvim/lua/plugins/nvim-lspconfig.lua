---@type LazyPluginSpec
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
  },
  config = function()
    vim.diagnostic.config({
      severity_sort = true, -- errors render on top of warnings on the same line
      underline = true, -- marks *which* token is wrong; the plugin only shows text
      signs = true, -- gutter sign, different column, doesn't collide
      update_in_insert = true, -- false => don't churn diagnostics while typing | true => update on insert
      virtual_text = false,
      float = {
        border = 'rounded',
        source = 'if_many',
      },
    })
    vim.filetype.add({
      filename = {
        ['docker-compose.yml'] = 'yaml.docker-compose',
        ['docker-compose.yaml'] = 'yaml.docker-compose',
        ['compose.yml'] = 'yaml.docker-compose',
        ['compose.yaml'] = 'yaml.docker-compose',
      },
    })
    vim.lsp.config('*', {
      root_markers = { '.git' },
    })
    local lsp_dir = vim.fn.stdpath('config') .. '/lsp'
    for entry, entry_type in vim.fs.dir(lsp_dir) do
      local server = entry:match('^(.*)%.lua$')
      if server and entry_type == 'file' then
        vim.lsp.config[server] = dofile(lsp_dir .. '/' .. entry)
      end
    end
    -- Mirrors `:Mason`, plus dartls. Add a name here only after installing it.
    vim.lsp.enable({
      'astro',
      'bashls',
      'clangd',
      'cssls',
      'dartls', -- from dart sdk!
      'docker_compose_language_service',
      'dockerls',
      'gopls',
      'html',
      'jsonls',
      'lua_ls',
      'marksman',
      'neocmake',
      'postgres_lsp', -- mason calls it postgres-language-server
      'tailwindcss',
      'tombi',
      'vtsls',
      'yamlls',
    })
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = event.buf })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover", buffer = event.buf })
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { desc = "View Diagnostics", buffer = event.buf })
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, { desc = "Next Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, { desc = "Previous Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("v", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { desc = "LSP References", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { desc = "LSP Rename", buffer = event.buf })
        vim.keymap.set("n", "<leader>vru", vim.lsp.buf.incoming_calls, { desc = "Find Uses (Incoming Calls)", buffer = event.buf })
      end,
    })
  end,
}
