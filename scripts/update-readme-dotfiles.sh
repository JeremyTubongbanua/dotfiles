#!/bin/sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
readme="$repo_dir/README.md"
install_script="$repo_dir/install.sh"
tmp_readme="$(mktemp)"
tmp_section="$(mktemp)"

cleanup() {
  rm -f "$tmp_readme" "$tmp_section"
}
trap cleanup EXIT

purpose_for() {
  case "$1" in
    dot/zshrc) printf 'Zsh shell configuration' ;;
    dot/config/nvim) printf 'Neovim configuration directory' ;;
    dot/config/ghostty) printf 'Ghostty terminal configuration directory' ;;
    dot/codex/AGENTS.md) printf 'Codex instructions' ;;
    dot/codex/config.toml) printf 'Codex user configuration' ;;
    dot/codex/agents) printf 'Codex sub-agent definitions' ;;
    dot/codex/rules/default.rules) printf 'Codex default rules' ;;
    dot/agents) printf 'Agents skills and lock file' ;;
    dot/pi/agent/settings.json) printf 'Pi agent settings' ;;
    *) printf 'Managed dotfile' ;;
  esac
}

{
  printf '<!-- DOTFILES_TOC_START -->\n'
  printf '## Dotfiles In Place\n\n'
  printf 'Run `scripts/update-readme-dotfiles.sh` to refresh this generated section.\n\n'
  printf '| Home path | Repo path | Purpose |\n'
  printf '| --- | --- | --- |\n'

  while IFS='|' read -r repo_path home_path; do
    [ -n "$repo_path" ] || continue
    purpose="$(purpose_for "$repo_path")"
    printf '| `%s` | `%s` | %s |\n' "$home_path" "$repo_path" "$purpose"
  done <<EOF
$(awk '
  /^link_path "\$repo_dir\// {
    repo = $0
    home = $0
    sub(/^link_path "\$repo_dir\//, "", repo)
    sub(/" "\$HOME\/.*$/, "", repo)
    sub(/^link_path "\$repo_dir\/[^"]+" "\$HOME\//, "~/", home)
    sub(/"$/, "", home)
    print repo "|" home
  }
' "$install_script")
EOF

  printf '<!-- DOTFILES_TOC_END -->\n'
} > "$tmp_section"

awk -v section="$tmp_section" '
  BEGIN {
    while ((getline line < section) > 0) {
      generated = generated line ORS
    }
  }
  /<!-- DOTFILES_TOC_START -->/ {
    printf "%s", generated
    skip = 1
    next
  }
  /<!-- DOTFILES_TOC_END -->/ {
    skip = 0
    next
  }
  !skip {
    print
  }
' "$readme" > "$tmp_readme"

if [ "${1:-}" = "--check" ]; then
  cmp -s "$readme" "$tmp_readme"
  exit $?
fi

if ! cmp -s "$readme" "$tmp_readme"; then
  cp "$tmp_readme" "$readme"
  printf 'Updated README dotfiles inventory.\n'
fi
