# nvim

Jeremy's personal neovim configuration

## Rough notes

- toggleterm -> tmux
- bufferline -> nothing
- nvim-tree -> oil
- snacks.picker
- gitsigns -> mini.diff
- persistence
- mini.ai
- mini.surround
- nvim-cmp --> blink.comp
  - Ctrl-n, Ctrl-p
  vim.opt.completeopt --> no select and no insert
  vim.opt.iskeyword --> ascii characters

- You need an empty `opts = {}` in order for a plugin to be loaded. Or a `config = function() /* code */ end,`. See code example in neovim:

```lua
if plugin.config or plugin.opts then
  M.config(plugin)
end
```

- We prefer `opts` over `config` in my configuration.

### List of brew formulaes needed

```
imagemagick
ghostscript
fd
node
ripgrep
pngpaste
tree-sitter
go
```

## vim notes

- `<Esc>` - exit to normal mode
- `i` - insert mode
- `a` - insert mode after cursor
- `v` - visual mode
- `V` - visual line mode
- `:` - command mode

- `o` - open new line below current line
- `O` - open new line above current line
- `dd` - delete current line

- `f{char}` - move to the next occurence of a char in the current line (forward)
- `F{char}` - same thing but backwards
- `t{char}` - move to before the next occurence of a char in the current line (forward)
- `T{char}` - same thing but backwards
- `ci{char}` - change inner of {char}
- `vf{char}S{char}` - visual mode, find char, surround with {char2}

- `S{char}` - in visual mode, surround selection with {char}

- `zf` - create a folder from selection
- `zd` - delete a folder from selection
- `zo` - open folder
- `zc` - close folder

- `/` to start search, then `n` for next or `N` for previous, then `<C-l>`

- `>` - indent line or selection of lines
- `<` - unindent line or selection of lines

## config/keymaps.lua

### Movement
- `<Alt-k>` - move a line up (normal mode)
- `<Alt-j>` - move a line down (normal mode)
- `<Alt-k>` - move selection up (visual mode)
- `<Alt-j>` - move selection down (visual mode)

## lua/plugins

### blink.cmp.lua

Auto completion plugin

- `<C-Space>` - trigger completion menu (insert mode)
- `<C-n>` - next item in completion menu (insert mode)
- `<C-p>` - previous item in completion menu (insert mode)

### catppuccin.lua

Neovim theme

### mini-diff.lua

Inline git diff signs (replaced gitsigns.nvim)

- Left gutter signs show added, changed, and deleted lines
- `<leader>gph` - toggle the inline diff overlay (shows the old lines in place)
- `<leader>gsh` - git stage hunk (normal: hunk under cursor, visual: selection)
- `<leader>grh` - git reset hunk (normal: hunk under cursor, visual: selection)
- `]c` - next git hunk
- `[c` - previous git hunk
- `ih` - hunk textobject, e.g. `dih` to delete a hunk

mini.diff has no blame, unstage-hunk, or diffthis, so these hand off to fugitive:

`<leader>gB` (toggle inline line blame) is gone - nothing equivalent exists.

### harpoon.lua

I use harpoon to navigate between frequently used files

- `<leader>a` to add current file to Harpoon menu
- `<Ctrl>e` to open Harpoon menu

### img-clip.lua

Paste image from clipboard into a markdown file

- `<leader>p` - paste image from clipboard into current md file

### lualine.lua

Custom status line for showing insert/normal mode, git branch, etc,

### markdown-preview.lua

Markdown preview in browser

- `:MarkdownPreview` - start preview
- `:MarkdownPreviewStop` - stop preview
- `:MarkdownPreviewToggle` - toggle preview

### nvim-lspconfig.lua

LSP configuration. nvim-lspconfig ships the default config for every server;
Mason installs the binaries and prepends its bin dir to PATH. There is no bridge
plugin between them, so servers are installed by hand with `:Mason` and started
only by the explicit `vim.lsp.enable()` list in this file. `dartls` is the one
server with no Mason package -- it comes from the Dart SDK. A server that will
not start means its binary is not on PATH.

Neovim 0.11+ automatically finds `~/.config/nvim/lsp/<server>.lua` on the
runtimepath and merges whatever table it returns into that server's config, so
each server's settings live in its own file there rather than in this one.

- `:Mason` - opens mason ui (`g?` for help inside it)
- `:checkhealth vim.lsp` - which servers attached, and why others did not

#### LSP Keymaps (when LSP is attached)

- `gd` - go to definition
- `K` - LSP hover (show documentation)
<!-- - `<leader>vws` - LSP workspace symbol search -->
- `<leader>vd` - view diagnostics in float window
- `[d` - next diagnostic
- `]d` - previous diagnostic
- `<leader>vca` - code action
- `<leader>vrr` - LSP references
- `<leader>vrn` - LSP rename symbol
- `grn` - rename symbol

### nvim-surround.lua

Helpful key maps to surround things with characters

- `cs{old_char}{new_char}` - change surrounding characters
- `ds{char}` - delete surrounding characters

### nvim-tree.lua

File explorer tree

- `<leader>e` - toggle nvim tree
- `E` - expand all folders recursively
- `W` - collapses all folders
- `P` - jumps to parent directory in tree
- `K` - jump to first sibling
- `J` - jump to last sibling
- `d` - delete a file
- `a` - append new file
- `<C-k>` - file info

### nvim-treesitter.lua

Syntax highlighting plugin

<!-- - `<leader>ss` - start selection -->
<!-- - `<leader>si` - selection increment -->
<!-- - `<leader>sc` - selection uppsr scope -->
<!-- - `<leader>sd` - selection decrement -->

- Uses syntax tree from `:InspectTree`

### nvim-treesitter-context.lua

Contains context for nvim tree sitter

- `mode = 'top'` - shows context at the top of the window (for example what class or function you're in)

### snacks.lua

Fuzzy finder (snacks.picker), plus dashboard, indent guides, notifier, etc.

- `<leader><leader>` - find file
- `<leader>ff` - find file
- `<leader>fg` - live grep

The picker is modal. It opens in insert mode so you can type to filter:

- `<Esc>` - drop to normal mode
- `j` / `k` - move down / up the result list
- `gg` / `G` - jump to first / last result
- `i` - back to insert mode
- `q` or `<Esc>` (normal mode) - close the picker

### vim-fugitive.lua

Git integration plugin

- `:G` or `:Git` - opens git status
- `<leader>gg` - opens git status
- `<leader>gd` - opens three-way git diff split
- `<leader>gh` - diff get left, available in normal and visual mode
- `<leader>gl` - diff get right, available in normal and visual mode
- `<leader>gq` - closes the git diff windows, leaving unrelated splits open

- `s` - stage
- `u` - unstage
- `cc` - commit
- `X` - discard changes
- `P` - push

### which-key.nvim

Shows suggestions after pressing a key in neovim. Good for beginners

### oil.nvim

- `-` to go up a directory
- `g.` to show hidden files
- `<C-l>` to refresh

### persistence.nvim

Session management plugin

Upon opening nvim, use `s` to restore last session (on Dashboard)

### flash.nvim

- `s{word}` - jump to place in current buffer
- `S{char}` - Flash using nvim-treesitter
