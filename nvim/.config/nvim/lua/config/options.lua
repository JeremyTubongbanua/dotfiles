vim.opt.showcmd = true
vim.opt.laststatus = 3 --  one big status line for split screens
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true

-- makes tab spaces to 2
vim.opt.backspace = '2'
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.expandtab = true -- any tab keys into spaces
vim.opt.inccommand = 'split' -- show effects of substitution incrementally in a split
vim.opt.smartindent = true -- nvim will intelligently indent lines based on context

-- split documentation below instead of top
vim.opt.splitright = true

vim.opt.shiftround = true
-- Contains all of the vim option stuff
vim.opt.clipboard = 'unnamedplus' -- synchronize with system clipboard

vim.opt.number = true -- set line numbers
vim.opt.relativenumber = true -- use relative line numbers
vim.opt.signcolumn = 'yes' -- keep the git/lsp sign column visible

-- vim.opt.wrap = false -- don't wrap lines
vim.opt.wrap = true -- wrap lines

vim.opt.termguicolors = true -- enable 24-bit colors, uses colours from terminal (Ghostty)

vim.opt.scrolloff = 999 -- always keep cursor in middle of screen

vim.opt.virtualedit = 'block' -- allow cursor to move where there is no text in visual block mode

-- searches become case sensitive
vim.opt.ignorecase = true -- case insensitive searching
vim.opt.smartcase = true -- 

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath('data') .. "/undodir" -- ~/.local/share/nvim
vim.opt.undofile = true

vim.opt.isfname:append("@-@") -- adds `@` to file names , good for ts
vim.opt.guicursor = "" -- basically when you're in insert mode, the normal mode cursor will remain

vim.opt.signcolumn = "yes" -- add gap to left side of line number for git signs etc
-- vim.cmd('set colorcolumn=0') -- highlight column 80

-- vim.o.cmdheight = 0 -- cmd line gonna be hidden under teh status line

-- adds a cool yank highlight animation thingy
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function()
    vim.hl.on_yank()
  end,
})
