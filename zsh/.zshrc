export TERMINAL="ghostty"
export EDITOR="nvim"
export VISUAL="nvim"

# Exports
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.scripts:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"

# pnpm
export PNPM_HOME="/Users/jeremytubongbanua/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Functions
darkmode() { osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'; }
lightmode() { osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'; }
togglemode() { osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'; }
claude() { CLAUDE_CONFIG_DIR="$HOME/.claude" command claude "$@"; }
claude-work() { CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"; }
ssh() {
    TERM=xterm-256color command ssh "$@"
}

# Aliases
alias python='python3'
alias pip='pip3'
alias h='herdr'
alias ccusage='CLAUDE_CONFIG_DIR="$HOME/.claude,$HOME/.claude-work" ccusage' # tracks both claude and claude-work for usage

set keyseq-timeout 0 # no key delays
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
eval "$(starship init zsh)"
