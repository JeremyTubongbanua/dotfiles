# nvim

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

Jeremy's personal neovim configuration

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
 
### copilot.lua

GitHub Copilot in Neovim

- `<Tab>` - accept a suggestion
- `:Copilot enable`
- `:Copilot disable`
- `:Copilot status`

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

- `<leader>guh` - opens `:Git` status, where `u` unstages
- `<leader>gb` - `:Git blame` split
- `<leader>gD` - `:Gvdiffsplit` against the index

`<leader>gB` (toggle inline line blame) is gone - nothing equivalent exists.

### harpoon2.lua

I use harpoon to navigate between frequently used files

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

### lsp.lua

LSP configuration. Mason is gone - server binaries are not managed by neovim.
They come from nix (`xavierchanth/dotfiles` `modules/shared/packages.nix`),
rustup (rust-analyzer), the system toolchain (clangd, dart), or a project's
`node_modules` (biome). A server that will not start means the binary is not on
PATH.

- `:checkhealth lsp` - to check if LSP is configured
- `:LspInfo` / `:che vim.lsp` - which servers attached to this buffer

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
<!-- - `<C-h>` - signature help (insert mode) -->
- `grn` - rename symbol

### nvim-surround.lua

Helpful key maps to surround things with characters

- `ys{motion}{char}` - add surounding characters
- `cs{old_char}{new_char}` - change surrounding characters
- `ds{char}` - delete surrounding characters
- Example: `ysiw'` - you surround inner word with single quotes
- Example: `cs"'` - change surrounding double quotes to single quotes
- Example: `ds(` - delete surrounding parentheses

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

### toggleterm.lua

Keeps terminal sessions alive

- `<C-/>` - toggle terminal (opens on the bottom)
- `<C-w>` - exit terminal mode and enable window commands (terminal mode)

### tokyonight.lua

Neovim theme 

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
- `f{char}`, `F{char}`, `t{char}`, `T{char}` - enhanced f/t motions, use f/t to jump to next iteration of {char}
- `yR` - remote flash
- `yr` - remote flash for single char

A nice motion is

- `vs{char}{selection}S{char}` - visual mode, flash to {char}, selection to {selection}, surround with {char}
