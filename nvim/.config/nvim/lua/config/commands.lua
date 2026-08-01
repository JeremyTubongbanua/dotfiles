vim.api.nvim_create_user_command("Q", "qall", { desc = "Quit all windows" })
vim.api.nvim_create_user_command("T", "terminal", { desc = "Open terminal in current window" })
vim.api.nvim_create_user_command("BDA", function()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local current_buf = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(bufs) do
    if buf.bufnr ~= current_buf then
      vim.api.nvim_buf_delete(buf.bufnr, { force = false })
    end
  end
end, { desc = "Delete all buffers except current" });
