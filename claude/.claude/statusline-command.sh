#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
rate_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Resolve active config dir (set by claude/claude-work shell functions)
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
email=$(jq -r '.oauthAccount.emailAddress // ""' "$config_dir/.claude.json" 2>/dev/null)
effort=$(jq -r '.effortLevel // ""' "$config_dir/settings.json" 2>/dev/null)

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Get git branch from the cwd (skip optional locks with GIT_OPTIONAL_LOCKS=0)
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

parts=""

# Git branch (green)
if [ -n "$git_branch" ]; then
  parts=$(printf '\033[32m%s\033[0m' "$git_branch")
fi

# Logged-in email (yellow)
if [ -n "$email" ]; then
  if [ -n "$parts" ]; then
    parts=$(printf '%s \033[90m|\033[0m \033[33m%s\033[0m' "$parts" "$email")
  else
    parts=$(printf '\033[33m%s\033[0m' "$email")
  fi
fi

# Model (with effort level in parens, e.g. "Opus 4.8 (xhigh)")
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    parts=$(printf '%s \033[90m|\033[0m \033[35m%s (%s)\033[0m' "$parts" "$model" "$effort")
  else
    parts=$(printf '%s \033[90m|\033[0m \033[35m%s\033[0m' "$parts" "$model")
  fi
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

  ctx_left=$(( 100 - used_int ))
  line2=$(printf '%bctx:%d%% left\033[0m' "$ctx_color" "$ctx_left")
fi

# 5-hour rate limit — show remaining (blue)
if [ -n "$rate_used" ]; then
  rate_int=$(printf '%.0f' "$rate_used")
  rate_left=$(( 100 - rate_int ))
  rate_color='\033[34m'
  line2=$(printf '%s \033[90m|\033[0m %busage:%d%% left\033[0m' "$line2" "$rate_color" "$rate_left")
fi

# Session cost in USD (cyan)
if [ -n "$cost" ]; then
  line2=$(printf '%s \033[90m|\033[0m \033[36m$%.4f USD\033[0m' "$line2" "$cost")
fi

# Line 1: branch | email | model | effort
# Line 2: cwd | ctx | usage | cost
printf '%s\n\033[36m%s\033[0m \033[90m|\033[0m %s' "$parts" "$short_cwd" "$line2"
