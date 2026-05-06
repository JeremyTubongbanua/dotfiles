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

copy_file() {
	source="$1"
	target="$2"

	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ] && ! cmp -s "$source" "$target"; then
		backup_target "$target"
	fi

	mkdir -p "$(dirname -- "$target")"
	cp -p "$source" "$target"
	printf 'Copied: %s -> %s\n' "$source" "$target"
}

copy_dir() {
	source="$1"
	target="$2"

	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ] && [ ! -d "$target" ]; then
		backup_target "$target"
	fi

	mkdir -p "$target"
	rsync -a --delete --exclude '.git/' "$source/" "$target/"
	printf 'Synced: %s/ -> %s/\n' "$source" "$target"
}

copy_path() {
	source="$1"
	target="$2"

	if [ -d "$source" ]; then
		copy_dir "$source" "$target"
	else
		copy_file "$source" "$target"
	fi
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

copy_path "$repo_dir/dot/zshrc" "$HOME/.zshrc"
copy_path "$repo_dir/dot/config/nvim" "$HOME/.config/nvim"
copy_path "$repo_dir/dot/config/ghostty" "$HOME/.config/ghostty"
copy_path "$repo_dir/dot/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
copy_path "$repo_dir/dot/codex/config.toml" "$HOME/.codex/config.toml"
copy_path "$repo_dir/dot/codex/agents" "$HOME/.codex/agents"
copy_path "$repo_dir/dot/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
copy_path "$repo_dir/dot/agents" "$HOME/.agents"
copy_path "$repo_dir/dot/pi/agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
copy_path "$repo_dir/dot/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
copy_path "$repo_dir/dot/pi/agent/agents" "$HOME/.pi/agent/agents"
copy_path "$repo_dir/dot/pi/agent/skills" "$HOME/.pi/agent/skills"
copy_path "$repo_dir/dot/pi/agent/extensions" "$HOME/.pi/agent/extensions"
install_hook

printf '\nDone. Managed dotfiles are real files in $HOME. Run scripts/sync-home-to-repo.sh to capture local changes.\n'
