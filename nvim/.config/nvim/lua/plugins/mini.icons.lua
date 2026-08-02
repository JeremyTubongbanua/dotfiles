-- icon provider -- https://github.com/nvim-mini/mini.icons
---@type LazyPluginSpec
return {
  'nvim-mini/mini.icons',
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    require('nvim-mini/mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons()
  end,
}
