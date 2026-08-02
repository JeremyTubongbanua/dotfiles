---@type LazyPluginSpec
return {
  'windwp/nvim-ts-autotag',
  lazy = false,
  dependencies = {
    'nvim-treesitter/nvim-treesitter'
  },
  opts = {
    -- Defaults
    enable_close = true, -- Auto close tags
    enable_rename = true, -- Auto rename pairs of tags
    enable_close_on_slash = false -- Auto close on trailing </
  },
  per_filetype = {
    ["html"] = {
      enable_close = false
    },
    ["markdown"] = {
      enable_close = false,
      enable_rename = false,
      enable_close_on_slash = false
    }
  },
}

