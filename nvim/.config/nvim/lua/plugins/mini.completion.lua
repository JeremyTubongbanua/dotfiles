---@type LazyPluginSpec
return {
  'nvim-mini/mini.completion',
  version = '*',
  opts = {},
  enabled = true,
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'snacks_picker_input',
      callback = function()
        vim.b.minicompletion_disable = true
      end,
      desc = 'Disable mini.completion in snacks picker input',
    })
  end,
}
