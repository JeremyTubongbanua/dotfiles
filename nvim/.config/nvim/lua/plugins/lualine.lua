return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons'
  },
  config = function()
    vim.o.laststatus = 0  -- no per-window bottom statusline; tabline + winbar cover it

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
            path = 1  -- 0 = just filename, 1 = relative path, 2 = absolute path, 3 = absolute path with ~ for home
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            'filename',
            path = 1
          },
        },
      },
      sections = {},
    })
  end,
}
