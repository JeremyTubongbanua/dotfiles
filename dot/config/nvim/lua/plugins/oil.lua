return {

  "stevearc/oil.nvim",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('oil').setup({
      default_file_explorer = true,
      keymaps = {
        ["gd"] = {
          callback = function()
            local path = vim.fn.input("Change directory to: ", "", "file")
            if path ~= "" then
              -- Expand ~ and other path shortcuts
              path = vim.fn.expand(path)
              require("oil").open(path)
            end
          end,
          desc = "Go to directory (cd)",
        },
        -- ["<CR>"] = {
        --   callback = function()
        --     local oil = require("oil")
        --     local entry = oil.get_cursor_entry()
        --
        --     if entry and entry.type == "file" then
        --       oil.select()
        --       vim.schedule(function()
        --         -- Wait for buffer to actually change to the file
        --         vim.defer_fn(function()
        --           local bufname = vim.api.nvim_buf_get_name(0)
        --           -- Only add to harpoon if we're not in an oil:// buffer
        --           if not bufname:match("^oil://") then
        --             local harpoon = require("harpoon")
        --             local list = harpoon:list()
        --
        --             -- Remove oldest if at max capacity (8)
        --             if #list.items >= 8 then
        --               list:remove_at(1)
        --             end
        --
        --             list:add()
        --           end
        --         end, 10)
        --       end)
        --     else
        --       oil.select()
        --     end
        --   end,
        --   desc = "Open and add to harpoon",
        -- },
      },
    })

    vim.keymap.set('n', '<leader>E', require('oil').open, { desc = 'Open Oil' })
  end,
}
