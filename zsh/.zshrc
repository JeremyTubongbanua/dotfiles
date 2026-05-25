# Oh My Zsh Configuration
set keyseq-timeout 0 # no key delays
# setopt COMBINING_CHARS # better paste for emojis

export ZSH="$HOME/.oh-my-zsh"
export GHOSTTY_SHELL_INTEGRATION_NO_TITLE=1

# export TERMINAL="ghostty"
# export EDITOR="nvim"
# export VISUAL="nvim"

ZSH_THEME="robbyrussell"
plugins=(git)
DISABLE_AUTO_TITLE="true"
source $ZSH/oh-my-zsh.sh

# Aliases
alias python='python3'
alias pip='pip3'
# alias cc='npx ccusage@latest'
# alias cmcp='~/scripts/cmcp'

# Functions
ssh() {
    TERM=xterm-256color command ssh "$@"
}

claude() {
    command claude "$@"
    local rc=$?
    _ghostty_apply_tab_title
    return $rc
}

_tabname_state_file() {
    local tab_tty
    tab_tty="$(tty 2>/dev/null)" || return 1
    [ "$tab_tty" = "not a tty" ] && return 1

    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tabname"
    mkdir -p "$state_dir"
    printf '%s/%s\n' "$state_dir" "${tab_tty:t}"
}

tabname() {
    if [ "$#" -eq 0 ]; then
        echo "usage: tabname <title>"
        return 2
    fi

    local state_file
    state_file="$(_tabname_state_file)" || return 1
    printf '%s\n' "$*" > "$state_file"
    _ghostty_apply_tab_title
}

tabreset() {
    local state_file
    state_file="$(_tabname_state_file)" || return 1
    rm -f "$state_file"
    _ghostty_apply_tab_title
}

_ghostty_apply_tab_title() {
    local title state_file
    title="${PWD:t}"

    if state_file="$(_tabname_state_file)" && [ -f "$state_file" ]; then
        title="$(cat "$state_file")"
    fi

    printf '\033]0;%s\007' "$title"
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

export PATH="$HOME/.scripts:$PATH"

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ghostty_apply_tab_title
add-zsh-hook chpwd _ghostty_apply_tab_title
