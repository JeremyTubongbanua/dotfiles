# dotfiles

My personal dotfiles, installed with [GNU stow](https://www.gnu.org/software/stow/). Files live in this repo; stow creates symlinks from `$HOME` into the matching paths here.

## Layout

Each top-level directory is a stow *package* whose contents mirror a subtree of `$HOME`:

```
zsh/         →  ~/.zshrc
nvim/        →  ~/.config/nvim/
ghostty/     →  ~/.config/ghostty/
codex/       →  ~/.codex/{AGENTS.md, config.toml, agents/, rules/default.rules}
agents/      →  ~/.agents/
claude/      →  ~/.claude/{CLAUDE.md, settings.json, agents/}
```

`AGENTS.md` has the operational details (adding files, packages, conflicts, folding behavior).

## Install

```sh
brew install stow
./install.sh
```

`install.sh` runs `stow --target "$HOME" --restow <packages>`. It's idempotent — re-run any time to repair or update symlinks.

If a target path is already a real file, stow refuses to clobber it. Move the file aside and rerun.

## Adding or Changing Tracked Files

See [AGENTS.md](AGENTS.md). Short version: drop the file into the right package directory at the path it would have under `$HOME` (with leading dots preserved), then `./install.sh`.
