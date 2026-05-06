-- Custom keymaps for Neovim (non-plugin related)
vim.api.nvim_create_user_command("Q", "qall", { desc = "Quit all windows" })
vim.api.nvim_create_user_command("T", "terminal", { desc = "Open terminal in current window" })

-- delete all buffers except current
vim.api.nvim_create_user_command("BDA", function()
 local bufs = vim.fn.getbufinfo({ buflisted = 1 })
 local current_buf = vim.api.nvim_get_current_buf()
 for _, buf in ipairs(bufs) do
   if buf.bufnr ~= current_buf then
     vim.api.nvim_buf_delete(buf.bufnr, { force = false })
   end
 end
end, { desc = "Delete all buffers except current" });

-- Movement keymaps
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

vim.keymap.set('n', '0', '0^', { desc = "Beginning of line" })

vim.keymap.set('v', '>', '>gv', { desc = "Indent right and reselect" })
vim.keymap.set('v', '<', '<gv', { desc = "Indent left and reselect" })
