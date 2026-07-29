set keyseq-timeout 0 # no key delays
# setopt COMBINING_CHARS # better paste for emojis

export TERMINAL="ghostty"
export EDITOR="nvim"
export VISUAL="nvim"

# Aliases
alias python='python3'
alias pip='pip3'
alias h='herdr'

# Functions
ssh() {
    TERM=xterm-256color command ssh "$@"
}

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

export PATH="$PATH":"$HOME/.pub-cache/bin"

eval "$(starship init zsh)"

# Claude multi-account: claude = personal, claude-work = work
claude() { CLAUDE_CONFIG_DIR="$HOME/.claude" command claude "$@"; }
claude-work() { CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"; }
# ccusage reads CLAUDE_CONFIG_DIR as a comma-separated list, so point it at BOTH
# account dirs to track usage across personal + work. Scoped to ccusage only,
# leaving Claude Code's own CLAUDE_CONFIG_DIR untouched.
alias ccusage='CLAUDE_CONFIG_DIR="$HOME/.claude,$HOME/.claude-work" ccusage'

export PATH="$HOME/.scripts:$PATH"

# pnpm
export PNPM_HOME="/Users/jeremytubongbanua/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
