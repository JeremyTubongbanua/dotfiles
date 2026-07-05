#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
rate_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Resolve active config dir (set by claude/claude-work shell functions)
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
email=$(jq -r '.oauthAccount.emailAddress // ""' "$config_dir/.claude.json" 2>/dev/null)

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Get git branch from the cwd (skip optional locks with GIT_OPTIONAL_LOCKS=0)
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

# Directory (cyan)
parts=$(printf '\033[36m%s\033[0m' "$short_cwd")

# Git branch (green with branch symbol)
if [ -n "$git_branch" ]; then
  parts=$(printf '%s \033[32m\xef\x9c\xa8 %s\033[0m' "$parts" "$git_branch")
fi

# Separator
parts=$(printf '%s \033[90m|\033[0m' "$parts")

# Logged-in email (yellow)
if [ -n "$email" ]; then
  parts=$(printf '%s \033[33m%s\033[0m' "$parts" "$email")
fi

# Model
if [ -n "$model" ]; then
  parts=$(printf '%s \033[90m|\033[0m \033[35m%s\033[0m' "$parts" "$model")
fi

# Context window usage + remaining tokens
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    ctx_color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then
    ctx_color='\033[33m'
  else
    ctx_color='\033[32m'
  fi

  if [ -n "$window_size" ]; then
    remaining_k=$(( window_size * (100 - used_int) / 100 / 1000 ))
    parts=$(printf '%s \033[90m|\033[0m %bctx:%d%% (%dk left)\033[0m' "$parts" "$ctx_color" "$used_int" "$remaining_k")
  else
    parts=$(printf '%s \033[90m|\033[0m %bctx:%d%%\033[0m' "$parts" "$ctx_color" "$used_int")
  fi
fi

# 5-hour rate limit — show remaining
if [ -n "$rate_used" ]; then
  rate_int=$(printf '%.0f' "$rate_used")
  rate_left=$(( 100 - rate_int ))
  if [ "$rate_left" -le 20 ]; then
    rate_color='\033[31m'
  elif [ "$rate_left" -le 50 ]; then
    rate_color='\033[33m'
  else
    rate_color='\033[90m'
  fi
  parts=$(printf '%s %busage:%d%% left\033[0m' "$parts" "$rate_color" "$rate_left")
fi

printf '%s' "$parts"
