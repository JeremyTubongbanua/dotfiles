-- useful plugin for showing function header as you scroll down
---@type LazyPluginSpec
return {
  'nvim-treesitter/nvim-treesitter-context',
  version = "*",
  opts = {
    enable = true,
    max_lines = 0,
    mode = 'topline',
  },
}
