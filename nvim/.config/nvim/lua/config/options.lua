vim.opt.showcmd = true -- shows commands while typing (like 14j) on the bottom right
vim.opt.cursorline = true -- highlights line that cursor is on
vim.opt.termguicolors = true -- enable 24-bit colors, uses colours from terminal (Ghostty)
vim.opt.signcolumn = 'yes' -- keep the git/lsp sign column visible, no layout jump
vim.opt.wrap = true -- true => wrap lines | false => don't wrap lines
vim.opt.virtualedit = 'block' -- allow cursor to move where there is no text in visual block mode
vim.opt.isfname:append("@-@") -- treats `@` as a valid filename character
-- vim.opt.guicursor = "" -- basically when you're in insert mode, the normal mode cursor will remain. Cursor will always be in block mode
vim.opt.splitright = true -- vertical splits will now open to the right
vim.opt.clipboard:append("unnamedplus") -- synchronize with system clipboard
vim.opt.inccommand = 'split' -- show effects of substitution incrementally in a split

vim.opt.autowrite = true -- auto saves current buffer before commands that leave it
vim.opt.autoread = true -- when file is edited outside of neovim, neovim will autodetect

-- Tab stuff
vim.opt.backspace = '2' -- backspace works over 2 space indents
vim.opt.tabstop = 2 -- make tabwidth 2
vim.opt.softtabstop = 2 -- make tabwidth 2
vim.opt.shiftwidth = 2 -- make tabwidth 2
vim.opt.expandtab = true -- any tab keys into spaces, not literal tab characters
vim.opt.smartindent = true -- nvim will intelligently indent lines based on context
vim.opt.shiftround = true -- >> and << shift will snap to multiples of `shiftwidth`

-- Line numbers
vim.opt.number = true -- set line numbers
vim.opt.relativenumber = true -- use relative line numbers

-- Case insensitivity | searches become case insensitive unless typing a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Editing safety
vim.opt.backup = false -- no file~ backups | vim/nvim saves a file, it keeps a file~ version as a backup copy alongside it. Setting this to false gets rid of that clutter
vim.opt.swapfile = false
vim.opt.undofile = true -- enables storing
vim.opt.undodir = vim.fn.stdpath('data') .. "/undodir" -- ~/.local/share/nvim | creates an undo directory so that undos are persistent between sessions. Normally only exists in memory so it does not persist when you close a file.

-- Adds a cool highlight animation flash when you yank
vim.api.nvim_create_autocmd(
  "TextYankPost",
  {
    desc = "Highlight when yanking (copying) text",
    callback = function()
      vim.hl.on_yank()
    end,
  }
)
