-- useful plugin for showing function header as you scroll down
return {
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup{
      enable = true,
      max_lines = 0,
      mode = 'topline',
    }
  end,
}
