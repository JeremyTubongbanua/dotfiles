-- icon provider -- https://github.com/nvim-mini/mini.icons
-- nvim-web-devicons is not installed; nvim-tree and oil both ask for it by
-- name, so mock it here and they get mini.icons instead.
return {
  'nvim-mini/mini.icons',
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    require('mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons()
  end,
}
