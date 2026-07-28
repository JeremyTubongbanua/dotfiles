return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons'
  },
  config = function()

    require('lualine').setup({
      options = {
        globalstatus = true,
      },
      tabline = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {},
        lualine_x = {'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      winbar = {
        lualine_c = {
          {
            'filename',
            -- 0 == just file name
            -- 1 == relative path
            -- 2 == absolute path
            -- 3 == abosulte path with ~ for home
            path = 1, 
            cond = function()
              return vim.fn.expand('%:t') ~= ''
            end,
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            'filename',
            path = 1,
            cond = function()
              return vim.fn.expand('%:t') ~= ''
            end,
          },
        },
      },
      sections = {},
    })
  end,
}
