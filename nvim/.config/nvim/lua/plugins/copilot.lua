return {
  "zbirenbaum/copilot.lua",
  opts = {
    suggestion = {
      auto_trigger = true,
    },
  },
  keys = {
    { "<leader>ce", function() require("copilot").setup({ enabled = true }) end, desc = "Enable Copilot" },
    { "<leader>cd", function() require("copilot").setup({ enabled = false }) end, desc = "Disable Copilot" },
  },
}
