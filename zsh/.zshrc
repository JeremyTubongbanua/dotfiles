# Oh My Zsh Configuration
set keyseq-timeout 0 # no key delays
# setopt COMBINING_CHARS # better paste for emojis

export ZSH="$HOME/.oh-my-zsh"

export TERMINAL="ghostty"
export EDITOR="nvim"
export VISUAL="nvim"

# ZSH_THEME="robbyrussell"
# plugins=(git)
# source $ZSH/oh-my-zsh.sh

# Aliases
alias python='python3'
alias pip='pip3'
# alias cc='npx ccusage@latest'
# alias cmcp='~/scripts/cmcp'

# Functions
ssh() {
    TERM=xterm-256color command ssh "$@"
}

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Environment Variables
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/opt/homebrew/opt/dart@3.7.2/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

export PATH="$PATH":"$HOME/.pub-cache/bin"

# Use a unique history file per terminal
# export HISTFILE=~/.zsh_history_$$
# setopt INC_APPEND_HISTORY
# setopt HIST_IGNORE_SPACE

eval "$(starship init zsh)"

# bun completions
[ -s "/Users/jeremytubongbanua/.bun/_bun" ] && source "/Users/jeremytubongbanua/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/Users/jeremytubongbanua/.bun/bin/bun "/Users/jeremytubongbanua/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Claude multi-account: claude = personal, claude-work = work
claude() { CLAUDE_CONFIG_DIR="$HOME/.claude" command claude "$@"; }
claude-work() { CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"; }

export PATH="$HOME/.scripts:$PATH"
