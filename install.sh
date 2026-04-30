#!/bin/sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"

backup_target() {
  target="$1"

  mkdir -p "$backup_dir"
  mv "$target" "$backup_dir/"
  printf 'Backed up %s to %s\n' "$target" "$backup_dir"
}

link_path() {
  source="$1"
  target="$2"

  if [ -L "$target" ]; then
    current="$(readlink "$target")"
    if [ "$current" = "$source" ]; then
      printf 'Already linked: %s -> %s\n' "$target" "$source"
      return
    fi
    backup_target "$target"
  elif [ -e "$target" ]; then
    if [ -f "$target" ] && cmp -s "$source" "$target"; then
      rm "$target"
    else
      backup_target "$target"
    fi
  fi

  mkdir -p "$(dirname -- "$target")"
  ln -s "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

install_hook() {
  hook_source="$repo_dir/scripts/pre-commit"
  hook_target="$repo_dir/.git/hooks/pre-commit"

  if [ ! -d "$repo_dir/.git/hooks" ]; then
    return
  fi

  if [ -L "$hook_target" ]; then
    current="$(readlink "$hook_target")"
    if [ "$current" = "$hook_source" ]; then
      printf 'Already linked: %s -> %s\n' "$hook_target" "$hook_source"
      return
    fi
    backup_target "$hook_target"
  elif [ -e "$hook_target" ]; then
    backup_target "$hook_target"
  fi

  ln -s "$hook_source" "$hook_target"
  printf 'Linked: %s -> %s\n' "$hook_target" "$hook_source"
}

link_path "$repo_dir/zshrc" "$HOME/.zshrc"
link_path "$repo_dir/config/nvim" "$HOME/.config/nvim"
link_path "$repo_dir/config/ghostty" "$HOME/.config/ghostty"
link_path "$repo_dir/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_path "$repo_dir/codex/config.toml" "$HOME/.codex/config.toml"
link_path "$repo_dir/codex/agents" "$HOME/.codex/agents"
link_path "$repo_dir/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
install_hook

printf '\nDone. Edits to linked dotfiles now modify this repo directly.\n'
