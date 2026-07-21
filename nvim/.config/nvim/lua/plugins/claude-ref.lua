-- Local plugin: in visual mode, copy a `path:start-end` reference (relative to
-- nvim's working dir) to the clipboard for pasting into Claude Code.
-- Source lives in ../../claude-ref.
return {
  dir = vim.fn.stdpath("config") .. "/claude-ref",
  name = "claude-ref",
  keys = {
    { "<leader>y", function() require("claude-ref").yank_range_ref() end, mode = "x", desc = "Yank code ref (path:lines)" },
  },
}
