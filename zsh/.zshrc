export TERMINAL="ghostty"
export EDITOR="nvim"
export VISUAL="nvim"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Exports
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.scripts:$PATH"
export PATH=/opt/homebrew/share/google-cloud-sdk/bin:"$PATH"
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
claude-work-x() { claude-work --model claude-opus-4-6[1m] --reasoning-effort high "$@"; }
codex-jl() { CODEX_HOME="$HOME/.codex-jl" command codex "$@"; }
ssh() {
    TERM=xterm-256color command ssh "$@"
}

# Aliases
alias pi='pi update --extensions && CLAUDE_CONFIG_DIR="$HOME/.claude-work" pi'
alias ccusage='CLAUDE_CONFIG_DIR="$HOME/.claude,$HOME/.claude-work" CODEX_HOME="$HOME/.codex,$HOME/.codex-jl" ccusage' # tracks all claude and codex accounts

bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Herdr: auto-start pi in the first pane of a new tab labelled "pi"
if [[ -o interactive && -n $HERDR_TAB_ID && -z $HERDR_PI_AUTOSTARTED ]] && (( $+commands[jq] )); then
  export HERDR_PI_AUTOSTARTED=1
  if [[ "$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null | jq -r '.result.tab | "\(.label) \(.pane_count)"')" == 'pi 1' ]]; then
    pi
  fi
fi
