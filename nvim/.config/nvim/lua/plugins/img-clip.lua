-- brew install pngpaste is needed
---@type LazyPluginSpec
return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  version = "*",
  opts = {
    default = {
      dir_path = function()
        return vim.fn.expand("%:p:h")
      end,
    },
    filetypes = {
      markdown = {
        template = "![$CURSOR]($FILE_PATH)",
      },
    },
  },
  keys = {
    { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
  },
}
