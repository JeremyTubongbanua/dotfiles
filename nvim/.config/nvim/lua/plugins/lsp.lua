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
        "tailwindcss",
      },
      automatic_installation = true,
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
    vim.lsp.config('*', {
      root_markers = { '.git' },
    })
    vim.lsp.config.lua_ls = {
      settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
    }
    vim.lsp.config.bashls = {
      filetypes = {
        'bash',
        'sh',
        'zsh'
      },
    }
    local ts_inlay_hints = {
      includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all'
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = false, -- noisy in TSX, most vars are obvious
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    }
    local ts_preferences = {
      importModuleSpecifier = 'shortest', -- respects tsconfig `paths` when shorter
      includeCompletionsForModuleExports = true, -- auto-import unimported symbols
      quotePreference = 'auto',
      jsxAttributeCompletionStyle = 'auto', -- fills `={}` / `=""` on JSX props
    }
    -- vtsls replaces ts_ls. It speaks VSCode setting names rather than the raw
    -- tsserver protocol ones, so the two tables above are translated here --
    -- note `suppressWhenArgumentMatchesName` is the inverse of the ts_ls key.
    local vtsls_ts = {
      inlayHints = {
        parameterNames = {
          enabled = ts_inlay_hints.includeInlayParameterNameHints,
          suppressWhenArgumentMatchesName = not ts_inlay_hints
            .includeInlayParameterNameHintsWhenArgumentMatchesName,
        },
        parameterTypes = { enabled = ts_inlay_hints.includeInlayFunctionParameterTypeHints },
        variableTypes = { enabled = ts_inlay_hints.includeInlayVariableTypeHints },
        propertyDeclarationTypes = { enabled = ts_inlay_hints.includeInlayPropertyDeclarationTypeHints },
        functionLikeReturnTypes = { enabled = ts_inlay_hints.includeInlayFunctionLikeReturnTypeHints },
        enumMemberValues = { enabled = ts_inlay_hints.includeInlayEnumMemberValueHints },
      },
      preferences = {
        importModuleSpecifier = ts_preferences.importModuleSpecifier,
        quoteStyle = ts_preferences.quotePreference,
        jsxAttributeCompletionStyle = ts_preferences.jsxAttributeCompletionStyle,
      },
      suggest = {
        autoImports = ts_preferences.includeCompletionsForModuleExports,
        completeFunctionCalls = true,
      },
      updateImportsOnFileMove = { enabled = 'always' },
    }
    vim.lsp.config.vtsls = {
      settings = { typescript = vtsls_ts, javascript = vtsls_ts },
    }
    vim.lsp.config.tailwindcss = {
      settings = {
        tailwindCSS = {
          classFunctions = { 'cn', 'clsx', 'cx', 'cva', 'tw', 'twMerge' },
        },
      },
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == '' then
          return
        end
        local config = vim.fs.find({
          'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts',
          'postcss.config.js', 'postcss.config.cjs', 'postcss.config.mjs', 'postcss.config.ts',
        }, { path = fname, upward = true })[1]
        if config then
          on_dir(vim.fs.dirname(config))
          return
        end
        local pkgs = vim.fs.find('package.json', { path = fname, upward = true, limit = math.huge })
        for _, pkg in ipairs(pkgs) do
          local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), '\n'))
          if ok and type(data) == 'table' then
            for _, field in ipairs({ 'dependencies', 'devDependencies', 'peerDependencies' }) do
              if type(data[field]) == 'table' and data[field].tailwindcss then
                on_dir(vim.fs.dirname(pkg))
                return
              end
            end
          end
        end
      end,
    }
    vim.lsp.config.dartls = {
      init_options = { onlyAnalyzeProjectsWithOpenFiles = false },
      settings = { dart = { updateImportsOnRename = true } },
    }
    vim.lsp.enable({
      -- scripting
      'lua_ls',
      'bashls',
      'ruff',
      'basedpyright',
      -- static
      'gopls',
      'dartls',
      -- systems
      'clangd',
      'neocmake',
      'rust_analyzer',
      'zls',
      -- markup
      'jsonls',
      'yamlls',
      'marksman',
      'tinymist',
      'tombi',
      -- docker
      'docker_compose_language_service',
      'dockerls',
      -- web
      'biome',
      'eslint',
      'astro',
      'svelte',
      'tailwindcss',
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
