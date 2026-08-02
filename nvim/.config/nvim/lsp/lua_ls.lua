-- Merged on top of nvim-lspconfig's own lsp/lua_ls.lua (cmd, filetypes, root_markers).
return {
  settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
}
