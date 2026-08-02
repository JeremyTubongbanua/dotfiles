---@type LazyPluginSpec
return {
  "iamcco/markdown-preview.nvim",
  version = "*",
  cmd = {
    "MarkdownPreviewToggle",
    "MarkdownPreview",
    "MarkdownPreviewStop"
  },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = {
    "markdown"
  },
}
