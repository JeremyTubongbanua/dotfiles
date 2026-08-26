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
    -- Dart/TS servers send window/showMessageRequest to confirm updating imports
    -- on file rename/move (regardless of which file explorer triggered it); always say yes
    local default_show_message_request = vim.lsp.handlers['window/showMessageRequest']
    vim.lsp.handlers['window/showMessageRequest'] = function(err, result, ctx, config)
      if result and result.message and result.message:lower():find('import') then
        for _, action in ipairs(result.actions or {}) do
          if action.title:lower():find('^yes') then
            return action
          end
        end
        return result.actions and result.actions[1]
      end
      return default_show_message_request(err, result, ctx, config)
    end
    local IMPORT_KINDS = { 'source.addMissingImports', 'source.organizeImports' }
    local function cursor_code_action_params(bufnr, encoding)
      local mode = vim.api.nvim_get_mode().mode
      if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
        return vim.lsp.util.make_range_params(0, encoding)
      end
      local from = vim.fn.getpos('v')
      local to = vim.fn.getpos('.')
      local start_row, start_col, end_row, end_col = from[2], from[3], to[2], to[3]
      if start_row == end_row and end_col < start_col then
        start_col, end_col = end_col, start_col
      elseif end_row < start_row then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
      end
      if mode == 'V' then
        start_col = 1
        end_col = #vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)[1]
      end
      return vim.lsp.util.make_given_range_params(
        { start_row, start_col - 1 },
        { end_row, end_col - 1 },
        bufnr,
        encoding
      )
    end
    local function file_code_action_params(bufnr, encoding)
      local last_row = vim.api.nvim_buf_line_count(bufnr)
      local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row - 1, last_row, true)[1]
      return vim.lsp.util.make_given_range_params(
        { 1, 0 },
        { last_row, math.max(#last_line - 1, 0) },
        bufnr,
        encoding
      )
    end
    local function apply_code_action(client, action, bufnr)
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
      if type(action.command) == 'table' then
        client:exec_cmd(action.command, { bufnr = bufnr })
      elseif type(action.command) == 'string' then
        client:exec_cmd(action, { bufnr = bufnr })
      end
    end
    local function run_code_action(client, action, bufnr)
      if action.edit or action.command or not client:supports_method('codeAction/resolve') then
        apply_code_action(client, action, bufnr)
        return
      end
      client:request('codeAction/resolve', action, function(err, resolved)
        if err or not resolved then
          vim.notify(err and err.message or ('Could not resolve: ' .. action.title), vim.log.levels.WARN)
          return
        end
        apply_code_action(client, resolved, bufnr)
      end, bufnr)
    end
    local function jq_filter(bufnr, args, label)
      if vim.fn.executable('jq') ~= 1 then
        vim.notify('jq not found; falling back to LSP formatting', vim.log.levels.WARN)
        vim.lsp.buf.format({ bufnr = bufnr })
        return
      end
      local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
      local cmd = { 'jq' }
      vim.list_extend(cmd, args)
      local result = vim.system(cmd, { stdin = input, text = true }):wait()
      if result.code ~= 0 then
        vim.notify(label .. ' failed: ' .. vim.trim(result.stderr or ''), vim.log.levels.ERROR)
        return
      end
      local view = vim.fn.winsaveview()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(vim.trim(result.stdout or ''), '\n'))
      vim.fn.winrestview(view)
    end
    local CUSTOM_ACTIONS = {
      json = {
        {
          title = 'Format JSON',
          run = function(bufnr)
            local indent = math.min(math.max(vim.bo[bufnr].shiftwidth, 1), 7)
            jq_filter(bufnr, { '--indent', tostring(indent), '.' }, 'Format JSON')
          end,
        },
        {
          title = 'Minify JSON',
          run = function(bufnr)
            jq_filter(bufnr, { '-c', '.' }, 'Minify JSON')
          end,
        },
      },
    }
    CUSTOM_ACTIONS.jsonc = CUSTOM_ACTIONS.json
    local function code_action_with_imports()
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeAction' })
      local cursor_diagnostics = vim.lsp.diagnostic.from(
        vim.diagnostic.get(bufnr, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
      )
      local file_diagnostics = vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr))
      local buckets = { {}, {} }
      local pending = #clients * #buckets
      local function show()
        pending = pending - 1
        if pending > 0 then
          return
        end
        local items, seen = {}, {}
        for _, action in ipairs(CUSTOM_ACTIONS[vim.bo[bufnr].filetype] or {}) do
          items[#items + 1] = { action = action, custom = action.run }
        end
        for _, bucket in ipairs(buckets) do
          for _, item in ipairs(bucket) do
            local key = item.client.id .. ':' .. item.action.title
            if not seen[key] then
              seen[key] = true
              items[#items + 1] = item
            end
          end
        end
        if #items == 0 then
          vim.notify('No code actions available', vim.log.levels.INFO)
          return
        end
        vim.ui.select(items, {
          prompt = 'Code Action:',
          kind = 'codeaction',
          format_item = function(item)
            return (item.action.title:gsub('%s*\r?\n%s*', ' '))
          end,
        }, function(item)
          if not item then
            return
          end
          if item.custom then
            item.custom(bufnr)
            return
          end
          run_code_action(item.client, item.action, bufnr)
        end)
      end
      local function request(client, bucket, params, context)
        params.context = vim.tbl_extend('error', context, {
          triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
        })
        local ok = client:request('textDocument/codeAction', params, function(err, result)
          for _, action in ipairs(err and {} or result or {}) do
            bucket[#bucket + 1] = {
              action = action,
              ctx = { bufnr = bufnr, client_id = client.id, method = 'textDocument/codeAction' },
              client = client,
            }
          end
          show()
        end, bufnr)
        if not ok then
          show()
        end
      end
      for _, client in ipairs(clients) do
        request(client, buckets[1], cursor_code_action_params(bufnr, client.offset_encoding), {
          diagnostics = cursor_diagnostics,
        })
        request(client, buckets[2], file_code_action_params(bufnr, client.offset_encoding), {
          diagnostics = file_diagnostics,
          only = IMPORT_KINDS,
        })
      end
      if #clients == 0 then
        show()
      end
    end
    vim.api.nvim_create_autocmd('FileType', {
      pattern = vim.tbl_keys(CUSTOM_ACTIONS),
      callback = function(event)
        vim.keymap.set({ 'n', 'v' }, '<leader>vca', code_action_with_imports, { desc = 'Code Action', buffer = event.buf })
      end,
    })
    local function is_uri_buffer(bufnr)
      return vim.api.nvim_buf_get_name(bufnr):match('^%a[%w+.%-]*://') ~= nil
    end
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        if is_uri_buffer(event.buf) then
          vim.diagnostic.enable(false, { bufnr = event.buf })
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = event.buf })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover", buffer = event.buf })
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { desc = "View Diagnostics", buffer = event.buf })
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, { desc = "Next Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, { desc = "Previous Diagnostic", buffer = event.buf })
        vim.keymap.set("n", "<leader>vca", code_action_with_imports, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("v", "<leader>vca", code_action_with_imports, { desc = "Code Action", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { desc = "LSP References", buffer = event.buf })
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { desc = "LSP Rename", buffer = event.buf })
        vim.keymap.set("n", "<leader>vru", vim.lsp.buf.incoming_calls, { desc = "Find Uses (Incoming Calls)", buffer = event.buf })
      end,
    })
  end,
}
