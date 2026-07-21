return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require('mason-lspconfig').setup({
      ensure_installed = {
        "lua_ls",
        "bashls",
        "eslint",
        "ts_ls",
        "gopls",
        "jsonls",
        "marksman",
        "yamlls",
        "astro",
      },
      automatic_installation = true,
    })

    vim.lsp.config('*', {
      root_markers = { '.git' },
    })

    vim.lsp.config.lua_ls = {}
    vim.lsp.config.bashls = {
      cmd = { 'bash-language-server', 'start' },
      filetypes = { 'sh', 'bash', 'zsh' },
      root_markers = { '.git', '.bashrc', '.bash_profile', '.zshrc' },
    }
    vim.lsp.config.eslint = {}
    vim.lsp.config.ts_ls = {}
    vim.lsp.config.gopls = {
      root_markers = { 'go.work', 'go.mod', '.git' },
    }
    vim.lsp.config.jsonls = {}
    vim.lsp.config.marksman = {}
    vim.lsp.config.yamlls = {}
    vim.lsp.config.astro = {
      root_markers = { 'astro.config.mjs', 'astro.config.js', 'package.json', '.git' },
    }

    vim.lsp.config.dartls = {
      cmd = { 'dart', 'language-server', '--protocol=lsp' },
      root_markers = { 'pubspec.yaml' },
      init_options = {
        onlyAnalyzeProjectsWithOpenFiles = false,
        suggestFromUnimportedLibraries = true,
        closingLabels = true,
        outline = true,
        flutterOutline = true,
      },
      settings = {
        dart = {
          analysisExcludedFolders = {},
          completeFunctionCalls = true,
          showTodos = true,
          updateImportsOnRename = true,
          includeDependenciesInWorkspaceSymblols = true,
        }
      }
    }

    vim.lsp.enable({
      'lua_ls',
      'bashls',
      'eslint',
      'ts_ls',
      'gopls',
      'jsonls',
      'marksman',
      'yamlls',
      'astro',
      'dartls',
    })

    -- LSP Keymaps
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = event.buf })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover", buffer = event.buf })
        -- vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, { desc = "LSP Workspace Symbol", buffer = event.buf })
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { desc = "View Diagnostics", buffer = event.buf })
        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, { desc = "Next Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("v", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { desc = "LSP References", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { desc = "LSP Rename", buffer = event.buf })
        vim.keymap.set("n", "<leader>vru", vim.lsp.buf.incoming_calls, { desc = "Find Uses (Incoming Calls)", buffer = event.buf })
        -- vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { desc = "Signature Help", buffer = event.buf })
      end,
    })
  end,
  dependencies = {
    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup({})
      end,
    },
    'neovim/nvim-lspconfig',
    'saghen/blink.cmp',
  },
}
