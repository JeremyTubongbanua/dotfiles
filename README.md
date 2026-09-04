# dotfiles

My personal dotfiles, installed with [GNU stow](https://www.gnu.org/software/stow/). Files live in this repo; stow creates symlinks from `$HOME` into the matching paths here.

## Layout

Each top-level directory is a stow *package* whose contents mirror a subtree of `$HOME`:

```text
zsh/         →  ~/.zshrc
nvim/        →  ~/.config/nvim/
ghostty/     →  ~/.config/ghostty/
agents/      →  ~/.agents/
claude/      →  ~/.claude/{CLAUDE.md, settings.json, agents/}
claude-work/ →  ~/.claude-work/{CLAUDE.md, settings.json, agents/, skills/}
pi/          →  ~/.pi/agent/{AGENTS.md, settings.json, provider-failover.json}, ~/.pi-lens/config.json
herdr/       →  ~/.config/herdr/
scripts/     →  ~/.scripts/
dockerfiles/ →  ~/.dockerfiles/
linearmouse/ →  ~/.config/linearmouse/linearmouse.json
ssh/         →  ~/.ssh/config
docker/      →  ~/.docker/daemon.json
git/         →  ~/.gitconfig, ~/.config/git/ignore
gh/          →  ~/.config/gh/config.yml
```

`AGENTS.md` has the operational details (adding files, packages, conflicts, folding behavior).
Pi discovers skills directly from `~/.agents/skills/`; its settings add `~/.agents/agents/` to pi-subagents discovery, and `~/.pi/agent/AGENTS.md` links to the shared `~/.agents/AGENTS.md` instructions.
The `pi` package excludes credentials, sessions, logs, caches, installed packages, and Pi Lens runtime data.

## Install

Install or repair every package:

```sh
brew install stow && cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow agents claude claude-work docker dockerfiles gh ghostty git herdr linearmouse nvim pi scripts ssh zsh
```

Stow packages are the top-level directories in this repo. Each package mirrors the path it should create under `$HOME`.

Useful commands:

```sh
# Preview every package before attempting a full restow.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --simulate --verbose --restow agents claude claude-work docker dockerfiles gh ghostty git herdr linearmouse nvim pi scripts ssh zsh

# Preview one or more packages without changing anything.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --simulate --verbose --restow git gh ssh

# Install or repair a subset of packages.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow git gh ssh

# Remove one package's symlinks from $HOME.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --delete git
```

If a target path is already a real file, stow refuses to clobber it. Compare it with the repo copy, move the real file aside, then restow the package:

```sh
diff -u ~/.gitconfig ~/GitHub/personal/dotfiles/git/.gitconfig
mkdir -p ~/.dotfiles-backup && mv ~/.gitconfig ~/.dotfiles-backup/.gitconfig && cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow git
```

## Adding or Changing Tracked Files

See [AGENTS.md](AGENTS.md). Short version: drop the file into the right package directory at the path it would have under `$HOME` with leading dots preserved, then restow everything:

```sh
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow agents claude claude-work docker dockerfiles gh ghostty git herdr linearmouse nvim pi scripts ssh zsh
```
