# dotfiles

My personal dotfiles, installed with [GNU stow](https://www.gnu.org/software/stow/). Files live in this repo; stow creates symlinks from `$HOME` into the matching paths here.

## Layout

Each top-level directory is a stow *package* whose contents mirror a subtree of `$HOME`:

```text
agents/      →  ~/.agents/
brew/        →  ~/Brewfile
claude/      →  ~/.claude/
claude-work/ →  ~/.claude-work/
codex/       →  ~/.codex/
docker/      →  ~/.docker/daemon.json
dockerfiles/ →  ~/.dockerfiles/
gh/          →  ~/.config/gh/config.yml
ghostty/     →  ~/.config/ghostty/
git/         →  ~/.gitconfig
herdr/       →  ~/.config/herdr/
linearmouse/ →  ~/.config/linearmouse/linearmouse.json
nvim/        →  ~/.config/nvim/
omp/         →  ~/.omp/agent/
pi/          →  ~/.pi/{agent/, web-search.json}, ~/.pi-lens/config.json
scripts/     →  ~/.scripts/
vorssaint/   →  ~/Vorssaint Settings.plist
zsh/         →  ~/.zshrc, ~/.config/spaceship.zsh
```

`AGENTS.md` has the operational details (adding files, packages, conflicts, folding behavior).

## Homebrew

`brew/Brewfile` is stowed as `~/Brewfile`. Install its formulae and casks with:

```sh
brew bundle --file "$HOME/Brewfile"
```

Run `./update-brewfile.sh` from the repo root to replace it with a snapshot of the currently installed Homebrew packages.

## Pi Provider Failover

Pi defaults to **Anthropic Claude Opus 4.6** and automatically fails over through two configured **OpenAI Codex GPT-5.6** accounts when Anthropic hits a rate or usage limit. It switches back when Anthropic becomes healthy again.

How it works:

1. An error matches a configured quota or rate-limit pattern.
2. Pi continues the interrupted task on the next model in the fallback chain.
3. Pi can probe Anthropic every 5 minutes, with rechecks capped at a 10-minute interval.
4. Once Anthropic is healthy again, Pi returns to it as the preferred provider.

Relevant config files:

| File | What it controls |
|------|------------------|
| `pi/.pi/agent/settings.json` | Default provider, model, thinking level, enabled models, packages, and subagent discovery |
| `pi/.pi/agent/provider-failover.json` | Fallback chain, provider priority, cooldowns, error patterns, recovery, and continuation behavior |

Pi discovers skills from `~/.agents/skills/`, scans `~/.agents/agents/` for subagents, and links `~/.pi/agent/AGENTS.md` to the shared `~/.agents/AGENTS.md` instructions.

The `pi` package excludes credentials, sessions, logs, caches, installed packages, and Pi Lens runtime data.

## Install

Install or repair every package:

```sh
brew install stow && cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow agents brew claude claude-work codex docker dockerfiles gh ghostty git herdr linearmouse nvim omp pi scripts vorssaint zsh
```

Stow packages are the top-level directories in this repo. Each package mirrors the path it should create under `$HOME`.

Useful commands:

```sh
# Preview every package before attempting a full restow.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --simulate --verbose --restow agents brew claude claude-work codex docker dockerfiles gh ghostty git herdr linearmouse nvim omp pi scripts vorssaint zsh

# Preview one or more packages without changing anything.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --simulate --verbose --restow codex git gh

# Install or repair a subset of packages.
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow codex git gh

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
cd ~/GitHub/personal/dotfiles && stow --target "$HOME" --restow agents brew claude claude-work codex docker dockerfiles gh ghostty git herdr linearmouse nvim omp pi scripts vorssaint zsh
```
