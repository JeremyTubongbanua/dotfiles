-- In visual mode, copy a `path:start-end` reference (relative to nvim's working dir) to the clipboard for pasting into a coding agent.
---@type LazyPluginSpec
return {
  "JeremyTubongbanua/coding-agent-copy.nvim",
  version = "*",
  opts = {
    path_style = "home", -- file path will be relative to home directory (e.g. ~/GitHub/...)
    prefix = "@", -- adds `@` to the very front of the text that is copied
    notify = false, -- removes status notification after copying
    separator = " (lines ", -- separate file and line numbers with a space
    suffix = ")",
  },
  keys = {
    {
      "<leader>y",
      function()
        require("coding-agent-copy").yank_range_ref()
      end,
      mode = "x",
      desc = "Yank code ref (path:lines)"
    },
  },
}
