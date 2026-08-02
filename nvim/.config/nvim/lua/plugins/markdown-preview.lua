---@type LazyPluginSpec
return {
  "iamcco/markdown-preview.nvim",
  cmd = {
    "MarkdownPreviewToggle",
    "MarkdownPreview",
    "MarkdownPreviewStop"
  },
  -- shell build, not `vim.fn["mkdp#util#install"]()`: lazy does not load the plugin
  -- for function builds, so the autoload is missing (E117). install.sh downloads the
  -- prebuilt binary synchronously; mkdp#util#install() only opens a terminal.
  build = "cd app && ./install.sh",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = {
    "markdown"
  },
}
