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
      main = { -- oil/terminal windows count as the window to open into
        file = false
      },
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
            ".wrangler",
          },
          actions = {
            -- with >1 window open, prompt for the target window before opening
            confirm_pick_win = function(picker, item, action)
              local explorer_confirm = require("snacks.explorer.actions").actions.confirm
              if not item or item.dir or picker.input.filter.meta.searching then
                return explorer_confirm(picker, item, action)
              end
              -- returns true when cancelled; `pick_win` no-ops with a single window
              if Snacks.picker.actions.pick_win(picker, item, action) then
                return
              end
              Snacks.picker.actions.jump(picker, item, action)
            end,
          },
          win = {
            list = {
              keys = {
                ["<CR>"] = "confirm_pick_win",
                ["<2-LeftMouse>"] = "confirm_pick_win",
              },
            },
          },
        },
        files = {
          hidden = true,
          exclude = {
            "node_modules",
            ".dart_tool",
            "dist",
            ".venv",
            "target",
            ".wrangler",
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
            ".wrangler",
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
        local loaded = false -- turns loading to false so text box can open instantly
        Snacks.picker.pick({
          source = "directories",
          title = "Directories",
          format = "file",
          show_empty = true, -- otherwise the empty first pass closes the picker
          filter = {
            transform = function(_, filter)
              loaded = loaded or filter.pattern ~= ""
              filter.search = loaded and "\1" or ""
            end,
          },
          -- snacks' `files` source hardcodes `-type f`, so drive a directory
          -- listing directly instead
          finder = function(opts, ctx)
            if ctx.filter.search == "" then -- don't search if search is empty
              return function() end
            end
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
