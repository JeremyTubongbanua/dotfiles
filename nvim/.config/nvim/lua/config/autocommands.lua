vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Strip trailing whitespace on save",
  group = vim.api.nvim_create_augroup("strip-trailing-whitespace", { clear = true }),
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
