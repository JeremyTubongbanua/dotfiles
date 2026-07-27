# dotfiles

My personal dotfiles, installed with [GNU stow](https://www.gnu.org/software/stow/). Files live in this repo; stow creates symlinks from `$HOME` into the matching paths here.

## Layout

Each top-level directory is a stow *package* whose contents mirror a subtree of `$HOME`:

```
zsh/         →  ~/.zshrc
nvim/        →  ~/.config/nvim/
ghostty/     →  ~/.config/ghostty/
agents/      →  ~/.agents/
claude/      →  ~/.claude/{CLAUDE.md, settings.json, agents/}
scripts/     →  ~/.scripts/
dockerfiles/ →  ~/.dockerfiles/
linearmouse/ →  ~/.config/linearmouse/linearmouse.json
ssh/         →  ~/.ssh/config
docker/      →  ~/.docker/daemon.json
git/         →  ~/.gitconfig, ~/.config/git/ignore
gh/          →  ~/.config/gh/config.yml
```

`AGENTS.md` has the operational details (adding files, packages, conflicts, folding behavior).

## Install

```sh
brew install stow
cd ~/GitHub/dotfiles
stow --target "$HOME" --restow <package>
```

Stow packages are the top-level directories in this repo. Each package mirrors the path it should create under `$HOME`.

Useful commands:

```sh
# Preview one or more packages without changing anything.
stow --target "$HOME" --simulate --verbose --restow git gh ssh

# Install or repair packages.
stow --target "$HOME" --restow git
stow --target "$HOME" --restow git gh ssh

# Remove one package's symlinks from $HOME.
stow --target "$HOME" --delete git

# Preview every package before attempting a full restow.
stow --target "$HOME" --simulate --verbose --restow zsh nvim ghostty agents claude scripts dockerfiles linearmouse ssh docker git gh
```

If a target path is already a real file, stow refuses to clobber it. Compare it with the repo copy, move the real file aside, then restow the package:

```sh
diff -u ~/.gitconfig ~/GitHub/dotfiles/git/.gitconfig
mkdir -p ~/.dotfiles-backup
mv ~/.gitconfig ~/.dotfiles-backup/.gitconfig
stow --target "$HOME" --restow git
```

## Adding or Changing Tracked Files

See [AGENTS.md](AGENTS.md). Short version: drop the file into the right package directory at the path it would have under `$HOME` with leading dots preserved, then restow that package:

```sh
stow --target "$HOME" --restow <package>
```
