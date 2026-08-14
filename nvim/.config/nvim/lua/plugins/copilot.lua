return {
  "zbirenbaum/copilot.lua",
  opts = {
    suggestion = {
      auto_trigger = true,
    },
  },
  keys = {
    { "<leader>ce", function() require("copilot.command").enable() end, desc = "Enable Copilot" },
    { "<leader>cd", function() require("copilot.command").disable() end, desc = "Disable Copilot" },
  },
}
