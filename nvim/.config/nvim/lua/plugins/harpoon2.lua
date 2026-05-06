return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-telescope/telescope.nvim",
    },
    config = function()
      local harpoon = require('harpoon');

      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
        },
        default = {
          get_root_dir = function()
            return vim.loop.cwd()
          end,
        },
      })
      -- Configure UI window size
      -- harpoon:extend({
      --   UI_CREATE = function(cx)
      --     vim.keymap.set("n", "<C-v>", function()
      --       harpoon.ui:select_menu_item({ vsplit = true })
      --     end, { buffer = cx.bufnr })
      --
      --     vim.keymap.set("n", "<C-x>", function()
      --       harpoon.ui:select_menu_item({ split = true })
      --     end, { buffer = cx.bufnr })
      --
      --     vim.keymap.set("n", "<C-t>", function()
      --       harpoon.ui:select_menu_item({ tabedit = true })
      --     end, { buffer = cx.bufnr })
      --   end,
      -- })

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = 'Add file to Harpoon' })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Toggle Harpoon Quick Menu' })
    end,
}
