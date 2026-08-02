-- teaches lua_ls about the neovim runtime + your installed plugins,
-- so plugin spec tables and `vim.*` get real completion & type checking
---@type LazyPluginSpec
return {
  'folke/lazydev.nvim',
  ft = 'lua',
  opts = {
    library = {
      -- `words` = only pull this library in when the pattern appears in the file
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'lazy.nvim',          words = { 'LazyPluginSpec' } },
    },
  },
}
