#!/bin/sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
failed=0

check_link() {
  source="$1"
  target="$2"

  if [ ! -L "$target" ]; then
    printf 'Not linked: %s should point to %s\n' "$target" "$source"
    failed=1
    return
  fi

  current="$(readlink "$target")"
  if [ "$current" != "$source" ]; then
    printf 'Wrong link: %s points to %s, expected %s\n' "$target" "$current" "$source"
    failed=1
  fi
}

while IFS='|' read -r repo_path home_path; do
  [ -n "$repo_path" ] || continue
  check_link "$repo_dir/$repo_path" "$HOME/$home_path"
done <<EOF
$(awk '
  /^link_path "\$repo_dir\// {
    repo = $0
    home = $0
    sub(/^link_path "\$repo_dir\//, "", repo)
    sub(/" "\$HOME\/.*$/, "", repo)
    sub(/^link_path "\$repo_dir\/[^"]+" "\$HOME\//, "", home)
    sub(/"$/, "", home)
    print repo "|" home
  }
' "$repo_dir/install.sh")
EOF

exit "$failed"
