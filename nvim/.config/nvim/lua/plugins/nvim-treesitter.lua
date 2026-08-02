-- highlighting plugin -- nvim-treesitter `main` branch (requires Neovim 0.12+)
-- :InspectTree   :TSInstall <language>   :TSUpdate
-- `main` is a full, incompatible rewrite of the old `master` API:
-- no `require("nvim-treesitter.configs").setup{}`, no highlight/indent modules.
---@type LazyPluginSpec
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- main branch does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({
      -- prepended to runtimepath so these parsers/queries take priority
      install_dir = vim.fn.stdpath("data") .. "/site",
    })
    -- parsers to install up front (async; no-op if already installed)
    ts.install({
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "astro",
      "javascript",
      "typescript",
      "tsx",
      "dart",
    })

    -- set of languages that actually have a parser (computed once). guards the
    -- auto-install below so non-code filetypes (oil, lazy, mason, ...) don't warn
    -- "skipping unsupported language".
    local available = {}
    for _, l in ipairs(ts.get_available()) do
      available[l] = true
    end
    -- per-buffer: start highlighting + treesitter indent, auto-installing the
    -- parser if missing. Replaces the old highlight/indent/auto_install modules.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local buf = args.buf
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if not lang or not available[lang] then
          return
        end

        local enable = vim.schedule_wrap(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          if not pcall(vim.treesitter.start, buf, lang) then
            return -- no parser / not a treesitter buffer
          end
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end)

        local ok, added = pcall(vim.treesitter.language.add, lang)
        if ok and added then
          enable()
        else
          ts.install({ lang }):await(enable) -- auto_install, then enable
        end
      end,
    })
  end,
}
