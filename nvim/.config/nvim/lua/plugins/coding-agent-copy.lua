-- In visual mode, copy a `path:start-end` reference (relative to nvim's working dir) to the clipboard for pasting into a coding agent.
---@type LazyPluginSpec
return {
  "JeremyTubongbanua/coding-agent-copy.nvim",
  branch = "trunk",
  opts = {
    path_style = "home",
    prefix = "@",
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
