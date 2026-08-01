-- lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim" -- ~.local/share/nvim/lazy/lazy.nvim

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ -- runs git clone command
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath) -- add lazy.nvim to runtime path
-- same as vim.opt.rpt.prepend(vim.opt.rtp, lazypath)
-- rpt is a lua table, so we can use the table functions on it

-- 'require' will look at the runtime path to find a directory (module) called 'lazy'
require("lazy").setup('plugins') -- load plugins from 'plugins' directory
