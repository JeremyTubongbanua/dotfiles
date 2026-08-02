return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require('mason-lspconfig').setup({
      ensure_installed = {
        "lua_ls",
        "bashls",
        "clangd",
        "ruff",
        "basedpyright",
        "gopls",
        "neocmake",
        "rust_analyzer",
        "jsonls",
        "yamlls",
        "marksman",
        "tombi",
        "docker_compose_language_service",
        "dockerls",
        "biome",
        "eslint",
        "astro",
        "svelte",
        "tailwindcss",
        "html",
        "cssls",
        "vtsls",
      },
      -- Guard, not dead weight: ts_ls is uninstalled, but if anything pulls it
      -- back in, mason-lspconfig would auto-enable it alongside vtsls and every
      -- TS diagnostic would appear twice.
      automatic_enable = { exclude = { "ts_ls" } },
    })

    vim.diagnostic.config({
      severity_sort = true, -- errors render on top of warnings on the same line
      underline = true, -- marks *which* token is wrong; the plugin only shows text
      signs = true, -- gutter sign, different column, doesn't collide
      update_in_insert = false, -- don't churn diagnostics while typing
      virtual_text = false,
      float = {
        border = 'rounded',
        source = 'if_many',
      },
    })
    -- Compose files arrive as plain `yaml`, so yamlls claimed them and
    -- docker_compose_language_service (which only handles `yaml.docker-compose`)
    -- never attached. The dotted filetype keeps yamlls attached as well.
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
    vim.lsp.enable({
      'lua_ls',
      'bashls',
      'ruff',
      'basedpyright',
      'gopls',
      'dartls', -- from dart sdk!
      'clangd',
      'neocmake',
      'rust_analyzer', -- needs rustup: `rustup toolchain install stable`
      'jsonls',
      'yamlls',
      'marksman',
      'tombi',
      'docker_compose_language_service',
      'dockerls',
      'biome',
      'eslint',
      'astro',
      'svelte',
      'tailwindcss',
      'html',
      'cssls',
      'vtsls',
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
  dependencies = {
    "williamboman/mason.nvim",
    'neovim/nvim-lspconfig',
    'saghen/blink.cmp',
  },
}
