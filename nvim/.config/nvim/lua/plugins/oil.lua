local open_directory = function()
  local oil = require('oil')
  local directory = vim.fn.input({
    prompt = 'Open directory: ',
    default = oil.get_current_dir() or vim.fn.getcwd(),
    completion = 'dir',
  })

  if directory ~= '' then
    oil.open(vim.fn.expand(directory))
  end
end

---@type LazyPluginSpec
return {
  "stevearc/oil.nvim",
  lazy = false, -- oil must be eager to disable netrw during setup
  dependencies = {
    'nvim-mini/mini.icons', -- icons in oil
  },
  keys = {
    { '<leader>E', function() require('oil').open() end, desc = 'Open Oil' },
  },
  opts = {
    default_file_explorer = true, -- want oil to take over directory buffers entirely
    keymaps = {
      ['<leader>cd'] = {
        callback = open_directory,
        desc = 'Open directory',
      },
    },
    view_options = {
      show_hidden = true, -- show hidden directories/files by default
    },
    lsp_file_methods = {
      -- oil sends willRenameFiles/didRenameFiles so LSP can fix imports on move/rename;
      -- "unmodified" writes only buffers that had no unrelated pending edits of your own
      autosave_changes = "unmodified",
    },
  },
}
