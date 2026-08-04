vim.api.nvim_create_autocmd("BufReadPre", {
  desc = "Keep LSP clients off fugitive:// blobs",
  group = vim.api.nvim_create_augroup("no-lsp-on-fugitive", { clear = true }),
  pattern = "fugitive://*",
  callback = function(event)
    vim.bo[event.buf].buftype = "nowrite"
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Strip trailing whitespace on save",
  group = vim.api.nvim_create_augroup("strip-trailing-whitespace", { clear = true }),
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
