#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Get git branch from the cwd (skip optional locks with GIT_OPTIONAL_LOCKS=0)
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi

# Directory (cyan, like Starship default)
parts=$(printf '\033[36m%s\033[0m' "$short_cwd")

# Git branch (green with branch symbol, like Starship default)
if [ -n "$git_branch" ]; then
  parts=$(printf '%s \033[32m\xef\x9c\xa8 %s\033[0m' "$parts" "$git_branch")
fi

# Separator
parts=$(printf '%s \033[90m|\033[0m' "$parts")

# Model
if [ -n "$model" ]; then
  parts=$(printf '%s \033[35m%s\033[0m' "$parts" "$model")
fi

# Context usage
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then
    color='\033[33m'
  else
    color='\033[32m'
  fi
  parts=$(printf '%s \033[90m|\033[0m %bctx:%d%%\033[0m' "$parts" "$color" "$used_int")
fi

printf '%s' "$parts"
