-- useful plugin for showing function header as you scroll down
return {
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup{
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
      mode = 'topline',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    }
  end,
}
