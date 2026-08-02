-- directory thing
-- --> use Oil, like netRW but makes sense
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

      -- Default mappings
      api.config.mappings.default_on_attach(bufnr)

      -- Custom mapping to add file to harpoon on open
      -- local function open_and_harpoon()
      --   local node = api.tree.get_node_under_cursor()
      --   if node then
      --     if node.type == 'file' then
      --       api.node.open.edit()
      --       vim.schedule(function()
      --         local harpoon = require("harpoon")
      --         local list = harpoon:list()
      --
      --         -- Remove oldest if at max capacity (8)
      --         if #list.items >= 8 then
      --           list:remove_at(1)
      --         end
      --
      --         list:add()
      --       end)
      --     elseif node.type == 'directory' then
      --       api.node.open.edit()
      --     end
      --   end
      -- end

      -- vim.keymap.set('n', '<CR>', open_and_harpoon, { buffer = bufnr, desc = 'Open and add to harpoon' })
      -- vim.keymap.set('n', 'o', open_and_harpoon, { buffer = bufnr, desc = 'Open and add to harpoon' })
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
