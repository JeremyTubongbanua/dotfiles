---@type LazyPluginSpec
return {
  'windwp/nvim-ts-autotag',
  version = "*",
  lazy = false, -- docs say not to lazy load it
  dependencies = {
    'nvim-treesitter/nvim-treesitter'
  },
  opts = { -- outer opts = lazy's
    opts = { -- inner opts = nvim-ts-autotag's
      enable_close = true, -- Auto close tags
      enable_rename = true, -- Auto rename pairs of tags
      enable_close_on_slash = false -- Auto close on trailing </
    },
    per_filetype = {
      ["markdown"] = {
        enable_close = false,
        enable_rename = false,
        enable_close_on_slash = false
      }
    },
  },
}

