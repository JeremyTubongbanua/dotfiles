---@type LazyPluginSpec
return {
  "folke/snacks.nvim",
  version = "*",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    animate = { enabled = true },
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    debug = { enabled = true },
    image = {
      enabled = true,
      doc = {
        enabled = false, -- disable inline rendering in markdown/documents
      },
    }, -- brew install imagemagick ghostscript
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        -- `hidden` shows this repo's dotted dirs (nvim/.config/...); snacks'
        -- rg/fd/find commands already prune .git, so only .jj needs excluding
        files = { hidden = true, exclude = { ".jj" } },
        grep = { hidden = true, exclude = { ".jj" } },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
  },
  keys = {
    { "<leader><leader>", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live Grep" },
    {
      "<leader>fd",
      function()
        Snacks.picker.pick({
          source = "directories",
          title = "Directories",
          format = "file",
          -- `fd` isn't installed and snacks' `files` source hardcodes `-type f`,
          -- so drive `find` directly to list directories instead
          finder = function(opts, ctx)
            local cwd = vim.fs.normalize(opts.cwd or vim.fn.getcwd())
            return require("snacks.picker.source.proc").proc({
              cmd = "find",
              cwd = cwd,
              args = { ".", "-type", "d", "-not", "-path", "*/.git/*", "-not", "-path", "*/.jj/*" },
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
