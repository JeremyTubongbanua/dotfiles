-- highlighting plugin
-- :InspectTree
-- :TSInstall <language>
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    -- This version of treesitter has a simplified API
    -- Highlighting is enabled by default via ftplugin
    -- To install parsers, use: :TSInstall <language>
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        'c',
        'lua',
        'vim',
        'vimdoc',
        'query',
        'astro',
        'javascript',
        'typescript',
        'tsx',
        'dart',
      }, -- parsers to install, even though auto_install will install other parsers as needed, these are recommended
      auto_install = true, -- when entering a buffer, if a parser is missing, install it
      highlight = {
        enable = true, -- enable each parser's highlights
      },
      indent = {
        enable = true, -- enable tree-sitter based indentation
      },
      -- incremental_selection = { -- when we select some text, it will select other things based on the syntax tree
      --   enable = true,
      --   keymaps = { -- some keys to control the selection
          -- init_selection = "<leader>ss", -- start selection (normal mode)
          -- node_incremental = "<leader>si", -- increment to the upper named parent (visual mode)
          -- scope_incremental = "<leader>sc", -- increment to the upper scope (as defined in locals.scm) (visual mode)
          -- node_decremental = "<leader>sd", -- decrement to the previous node (visual mode)
      --   },
      -- },
    })
  end,
}
