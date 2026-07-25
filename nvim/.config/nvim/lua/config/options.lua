-- vim.o, vim.g are all meta accessors
vim.g.mapleader = " " -- leader key is space
vim.g.maplocalleader = "\\"

vim.opt.backspace = '2'
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true
-- Contains all of the vim option stuff
vim.opt.clipboard = 'unnamedplus' -- synchronize with system clipboard

vim.opt.number = true -- set line numbers
vim.opt.relativenumber = true -- use relative line numbers
vim.opt.signcolumn = 'yes' -- keep the git/lsp sign column visible

-- set tab size to 2 spaces
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "*",
--   callback = function()
-- vim.opt_local.shiftwidth = 2
-- vim.opt_local.tabstop = 2
-- vim.opt_local.softtabstop = 2
--   end,
-- vim.opt.tabstop = 2 -- a tab character is 2 spaces wide
-- vim.opt.softtabstop = 2
-- vim.opt.expandtab = true -- tabs are a series of spaces
vim.opt.smartindent = true -- nvim will intelligently indent lines based on context

-- vim.opt.wrap = false -- don't wrap lines
vim.opt.wrap = true -- wrap lines

vim.opt.termguicolors = true -- enable 24-bit colors, uses colours from terminal (Ghostty)

vim.opt.scrolloff = 999 -- always keep cursor in middle of screen

vim.opt.virtualedit = 'block' -- allow cursor to move where there is no text in visual block mode

vim.opt.inccommand = 'split' -- show effects of substitution incrementally in a split

vim.opt.ignorecase = true -- case insensitive searching

vim.cmd('set colorcolumn=80') -- highlight column 80
