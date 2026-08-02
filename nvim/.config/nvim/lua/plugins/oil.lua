---@type LazyPluginSpec
return {
  "stevearc/oil.nvim",
  lazy = false, -- oil must be eager to disable netrw during setup
  dependencies = {
    'nvim-mini/mini.icons', -- icons in oil
  },
  keys = {
    { '<leader>E', function() require('oil').open() end, desc = 'Open Oil' },
  },
  opts = {
    default_file_explorer = true, -- want oil to take over directory buffers entirely
    view_options = {
      show_hidden = true, -- show hidden directories/files by default
    },
  },
}
