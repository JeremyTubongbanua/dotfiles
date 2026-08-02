-- oil buffers have no real file name, so show the directory oil is browsing instead
local oil_dir = {
  function()
    local dir = require('oil').get_current_dir(0)
    return dir and vim.fn.fnamemodify(dir, ':~') or ''
  end,
  cond = function()
    return vim.bo.filetype == 'oil'
  end,
}

local filename = {
  'filename',
  -- 0 == just file name
  -- 1 == relative path
  -- 2 == absolute path
  -- 3 == abosulte path with ~ for home
  path = 1,
  cond = function()
    return vim.bo.filetype ~= 'oil' and vim.fn.expand('%:t') ~= ''
  end,
}

---@type LazyPluginSpec
return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'echasnovski/mini.diff',
  },
  opts = {
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
      lualine_c = { oil_dir, filename },
    },
    inactive_winbar = {
      lualine_c = { oil_dir, filename },
    },
    sections = {},
  },
}
