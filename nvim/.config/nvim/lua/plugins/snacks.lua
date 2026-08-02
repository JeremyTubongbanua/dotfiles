---@type LazyPluginSpec
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    dashboard = {
      enabled = true,
      preset = {
        keys = {
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    explorer = { -- sidebar file tree, `<leader>e`
      enabled = true,
      replace_netrw = false, -- oil owns directory buffers, don't fight it
    },
    image = { -- image viewer => `brew install imagemagick ghostscript`
      enabled = true,
      doc = {
        enabled = false, -- disable inline rendering in markdown/documents
      },
    },
    indent = { -- indent lines in a file
      enabled = true
    },
    input = { -- nice top input form for things like `vrn`
      enabled = true
    },
    notifier = { -- adds notifier to the top right
      enabled = true
    },
    picker = { -- `<leader><leader>|<leader>ff and <leader>fg`
      enabled = true,
      sources = {
        explorer = {
          enter = false, -- opening it shouldn't move my cursor, it's a view
          focus = "list", -- when we `<C-w>h`, it enters in normal mode. default behaviour puts us in insert to search
          hidden = true,
          exclude = {
            "node_modules",
            ".dart_tool",
            "dist",
            ".venv",
            "target",
          }
        },
        files = {
          hidden = true,
          exclude = {
            "node_modules",
            ".dart_tool",
            "dist",
            ".venv",
            "target",
          }
        },
        grep = {
          hidden = true,
          exclude = {
            "node_modules",
            ".dart_tool",
            "dist",
            ".venv",
            "target",
          }
        },
      },
    },
    scope = { -- vii and vai, and [i and ]i
      enabled = true,
    },
    scroll = { -- smooth animation scrolling when Ctrl+U and Ctrl+D for example
      enabled = true,
    },
  },
  keys = {
    { "<leader><leader>", function() Snacks.picker.files() end, desc = "Find Files" },
    {
      "<leader>e",
      function()
        local explorer = Snacks.picker.get({
          source = "explorer"
        })[1]

        -- toggles explorer
        if explorer then
          explorer:close()
          return
        end

        -- if we are currently in an oil dir, then open that in explorer
        local oil_dir = vim.bo.filetype == "oil" and require("oil").get_current_dir(0) or nil
        Snacks.explorer.reveal({ file = oil_dir })
      end,
      desc = "Toggle Explorer",
    },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live Grep" },
    {
      "<leader>fd",
      function()
        Snacks.picker.pick({
          source = "directories",
          title = "Directories",
          format = "file",
          -- snacks' `files` source hardcodes `-type f`, so drive a directory
          -- listing directly instead
          finder = function(opts, ctx)
            local cwd = vim.fs.normalize(opts.cwd or vim.fn.getcwd())
            return require("snacks.picker.source.proc").proc({
              cmd = "find",
              cwd = cwd,
              args = {
                ".",
                "-type", "d",
                "-not", "-path", "*/.git/*",
                "-not", "-path", "*/.jj/*",
                "-not", "-path", "*/node_modules/*",
                "-not", "-name", "node_modules",
              },
              transform = function(item)
                item.cwd = cwd
                item.file = item.text
                item.dir = true
              end,
            }, ctx)
          end,
          confirm = function(picker, item)
            picker:close()
            if item then
              require("oil").open(Snacks.picker.util.path(item))
            end
          end,
        })
      end,
      desc = "Find Directory (Oil)",
    },
  },
}
