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

    -- Diagnostic display. The message text itself is drawn by
    -- tiny-inline-diagnostic.nvim; everything set here is the surrounding chrome
    -- (gutter sign, undercurl on the bad range, the <leader>vd float).
    vim.diagnostic.config({
      severity_sort = true, -- errors render on top of warnings on the same line
      underline = true, -- marks *which* token is wrong; the plugin only shows text
      signs = true, -- gutter sign, different column, doesn't collide
      update_in_insert = false, -- don't churn diagnostics while typing
      -- tiny-inline-diagnostic.nvim owns the message display. Leaving this on
      -- would append a truncated copy at end-of-line, i.e. draw everything twice.
      -- virtual_lines is left at its default (false) for the same reason.
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
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          diagnostics = { globals = { 'vim' } },
          workspace = {
            library = vim.api.nvim_get_runtime_file('', true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    }
    vim.lsp.config.bashls = {
      cmd = { 'bash-language-server', 'start' },
      filetypes = { 'sh', 'bash', 'zsh' },
      root_markers = { '.git', '.bashrc', '.bash_profile', '.zshrc' },
    }
    vim.lsp.config.eslint = {}

    -- typescript-language-server takes the same shape under `typescript` and
    -- `javascript`, so build it once and reuse. Hints are served but not shown
    -- until `<leader>vh` toggles them on (see keymaps below).
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

    vim.lsp.config.ts_ls = {
      settings = {
        -- tsserver won't offer function-call snippets without this
        completions = { completeFunctionCalls = true },
        typescript = {
          inlayHints = ts_inlay_hints,
          preferences = ts_preferences,
          updateImportsOnFileMove = { enabled = 'always' },
        },
        javascript = {
          inlayHints = ts_inlay_hints,
          preferences = ts_preferences,
          updateImportsOnFileMove = { enabled = 'always' },
        },
      },
    }
    vim.lsp.config.gopls = {
      root_markers = { 'go.work', 'go.mod', '.git' },
    }
    vim.lsp.config.jsonls = {}
    vim.lsp.config.marksman = {}
    vim.lsp.config.yamlls = {}
    vim.lsp.config.astro = {
      root_markers = { 'astro.config.mjs', 'astro.config.js', 'package.json', '.git' },
    }

    vim.lsp.config.tailwindcss = {
      settings = {
        tailwindCSS = {
          -- also complete classes inside cn()/clsx()/cva() wrappers, not just className
          classFunctions = { 'cn', 'clsx', 'cx', 'cva', 'tw', 'twMerge' },
        },
      },
      -- Overrides lspconfig's root_dir. Tailwind v4 needs no tailwind.config.*, so
      -- lspconfig falls back to `.git` -- which starts this server in every git repo
      -- for any js/ts/css/markdown buffer. Require a real Tailwind signal instead.
      root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == '' then
          return
        end

        -- v3 and earlier: an explicit config file marks the project root
        local config = vim.fs.find({
          'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts',
          'postcss.config.js', 'postcss.config.cjs', 'postcss.config.mjs', 'postcss.config.ts',
        }, { path = fname, upward = true })[1]
        if config then
          on_dir(vim.fs.dirname(config))
          return
        end

        -- v4: no config file, so use the nearest package.json that actually
        -- depends on tailwindcss. In a monorepo this lands on the package dir.
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
        -- no Tailwind anywhere above this file: never call on_dir, server stays down
      end,
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
      'tailwindcss',
      'dartls',
    })

    -- LSP Keymaps
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = event.buf })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover", buffer = event.buf })
        -- vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, { desc = "LSP Workspace Symbol", buffer = event.buf })
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { desc = "View Diagnostics", buffer = event.buf })
        -- `]` is forward and `[` is backward, per vim convention. goto_next/goto_prev
        -- are deprecated in 0.11+; vim.diagnostic.jump replaces both.
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, { desc = "Next Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, { desc = "Previous Diagnostic", buffer = event.buf })
        -- silence the inline message when it's in the way of reading the code
        vim.keymap.set("n", "<leader>vv", function()
          require('tiny-inline-diagnostic').toggle()
        end, { desc = "Toggle Inline Diagnostics", buffer = event.buf })
        vim.keymap.set("n", "<leader>vh", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
            { bufnr = event.buf })
        end, { desc = "Toggle Inlay Hints", buffer = event.buf })
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("v", "<leader>vca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { desc = "LSP References", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { desc = "LSP Rename", buffer = event.buf })
        vim.keymap.set("n", "<leader>vru", vim.lsp.buf.incoming_calls, { desc = "Find Uses (Incoming Calls)", buffer = event.buf })
        -- vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { desc = "Signature Help", buffer = event.buf })

        -- ts_ls only: whole-file `source.*` actions (organize imports, add all
        -- missing imports, remove unused). tsserver hides these from the normal
        -- code_action list, so they need the dedicated command lspconfig defines.
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == "ts_ls" then
          vim.keymap.set("n", "<leader>vi", "<cmd>LspTypescriptSourceAction<cr>",
            { desc = "TS Source Action (organize/add imports)", buffer = event.buf })
        end
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
