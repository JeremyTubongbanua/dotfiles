-- fuzzy finder -- https://github.com/ibhagwan/fzf-lua
-- requires the `fzf` binary: brew install fzf
return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    files = {
      -- fzf-lua's defaults already prune .git/.jj but omit --hidden, which would
      -- hide this repo's dotted dirs (nvim/.config/...). fd isn't installed here
      -- so rg is what actually runs; fd_opts is set too in case fd shows up later.
      rg_opts = [[--color=never --files --hidden -g "!.git" -g "!.jj"]],
      fd_opts = [[--color=never --type f --type l --hidden --exclude .git --exclude .jj]],
    },
  },
  keys = {
    { '<leader><leader>', function() require('fzf-lua').files() end, desc = 'Find Files' },
    { '<leader>ff', function() require('fzf-lua').files() end, desc = 'Find Files' },
  },
}
