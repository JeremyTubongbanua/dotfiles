#!/bin/sh
set -eu
cd "$(dirname -- "$0")"
stow --target "$HOME" --restow zsh nvim ghostty codex agents claude
echo 'Done. Symlinks installed under $HOME via stow.'
