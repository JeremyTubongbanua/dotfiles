-- vim.o, vim.g are all meta accessors

-- Leader keys
vim.g.mapleader = " " -- leader key is space
vim.g.maplocalleader = "\\"

-- Move a line (or collection of lines)
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Go to beginning of line (first character, even if indented)
vim.keymap.set('n', '0', '0^', { desc = "Beginning of line" })

-- Indent a selection without having to re-select
vim.keymap.set('v', '>', '>gv', { desc = "Indent right and reselect" })
vim.keymap.set('v', '<', '<gv', { desc = "Indent left and reselect" })

-- `x`, `p`, `d`, `dd` no longer overwrite register
-- vim.keymap.set('x', 'x', '"_x', { desc = "Delete without overwriting register" })
-- vim.keymap.set('x', 'd', '"_d', { desc = "Delete without overwriting register" })
-- vim.keymap.set('x', 'p', '"_dP ', { desc = "Paste without overwriting register" })
-- vim.keymap.set('n', 'dd', '"_dd', { desc = "Delete line without overwriting register" })

-- move down/up in buffer with cursor centered
-- vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = "Move down half page and center cursor" })
-- vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = "Move up half page and center cursor" })
