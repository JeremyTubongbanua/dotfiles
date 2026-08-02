-- let's me do `cs"'` (change " to ')
---@type LazyPluginSpec
return {
  'kylechui/nvim-surround',
  config = function()
    require('nvim-surround').setup({})
  end,
}
