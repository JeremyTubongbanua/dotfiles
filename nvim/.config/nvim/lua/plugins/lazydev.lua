-- teaches lua_ls about the neovim runtime + your installed plugins,
-- so plugin spec tables and `vim.*` get real completion & type checking
---@type LazyPluginSpec
return {
  'folke/lazydev.nvim',
  ft = 'lua',
  opts = {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'lazy.nvim',          words = { 'LazyPluginSpec' } },
    },
  },
}
