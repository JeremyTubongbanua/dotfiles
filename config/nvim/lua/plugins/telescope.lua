-- fuzzy finder
return {
  'nvim-telescope/telescope.nvim',
  branch = 'master',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('telescope').setup({
      defaults = {
        initial_mode = 'insert',
        file_previewer = require('telescope.previewers').vim_buffer_cat.new,
        grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
        qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
      },
    })
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader><leader>', function()
      builtin.find_files({ hidden = true })
    end, { desc = 'Telescope Find Files' })
    -- vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope Find Files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope Live Grep' })

    -- local telescope = require('telescope')

    -- local function add_to_harpoon_on_select(prompt_bufnr)
    --   local actions = require("telescope.actions")
    --
    --   actions.select_default(prompt_bufnr)
    --
    --   vim.schedule(function()
    --     require("harpoon"):list():add()
    --   end)
    -- end
    --
    -- telescope.setup({
    --   defaults = {
    --     mappings = {
    --       i = { ["<CR>"] = add_to_harpoon_on_select },
    --       n = { ["<CR>"] = add_to_harpoon_on_select },
    --     },
    --   },
    -- })
  end,
}
