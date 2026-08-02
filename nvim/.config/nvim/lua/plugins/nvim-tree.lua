-- directory thing
-- --> use Oil, like netRW but makes sense
---@type LazyPluginSpec
return {
  'nvim-tree/nvim-tree.lua',
  version = "*",
  lazy = false,
  dependencies = {
    'nvim-mini/mini.icons',
  },
  config = function()
    local function on_attach(bufnr)
      local api = require('nvim-tree.api')
      api.config.mappings.default_on_attach(bufnr)
    end

    require('nvim-tree').setup({
      sync_root_with_cwd = true, -- keeps directory in sync with cwd
      respect_buf_cwd = true, -- keeps directory in sync with buffer cwd, so doing something like `:cd <dir>` will update the nvim-tree
      update_focused_file = {
        enable = true, -- automatically find and highlight the current file
        update_root = false, -- don't change the root directory when switching files
      },
      on_attach = on_attach,
    })
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
  end,
}

-- return {}
