-- icon provider -- https://github.com/nvim-mini/mini.icons
---@type LazyPluginSpec
return {
  'nvim-mini/mini.icons',
  version = "*",
  lazy = false,
  priority = 1000,
  config = function()
    require('mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons() -- required for nvim-tree icons to work
  end,
}
