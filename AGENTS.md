# Agent Guide

Operational instructions for AI agents working in this dotfiles repo. Humans should read `README.md` first.

## Convention

This repo uses [GNU stow](https://www.gnu.org/software/stow/) to install dotfiles. Each top-level directory in the repo is a *stow package* whose contents mirror a subtree of `$HOME` with leading dots preserved.

```
zsh/.zshrc                  →  ~/.zshrc
nvim/.config/nvim/init.lua  →  ~/.config/nvim/init.lua
codex/.codex/config.toml    →  ~/.codex/config.toml
```

Files inside a package are *real files in the repo*. After `stow`, the matching paths in `$HOME` are symlinks pointing back into the repo. Editing through either path edits the same inode.

## Activation

`install.sh` is a one-line wrapper:

```sh
stow --target "$HOME" --restow zsh nvim ghostty codex agents claude
```

`--restow` is idempotent: re-running with no changes prints nothing and modifies nothing. If a target path is already occupied by something other than the expected symlink, stow refuses to clobber and prints a conflict.

`.stow-global-ignore` at the repo root tells stow which files to skip in every package (`README.md`, `AGENTS.md`, `LICENSE`, `install.sh`, `.git`, etc.).

## Tree Folding

By default, stow makes a single directory symlink when nothing in `$HOME` is in the way. For example, `~/.config/nvim` is a single symlink to `nvim/.config/nvim/` because nothing else owns files under that path. New files dropped into the repo dir appear immediately under `~/.config/nvim` without re-stowing.

Folding is automatically *prevented* when the destination directory already contains files (e.g. `~/.codex/auth.json`, `~/.claude/sessions/`). In that case stow falls back to per-file linking, which is what we want for tools that write runtime state alongside their config.

## Adding a Tracked File

1. Identify the package (or create a new one — see below).
2. Place the file inside the package at the path it would have under `$HOME`, **with leading dots preserved**:
   ```
   ~/.foo/bar.toml  →  <package>/.foo/bar.toml
   ```
3. Review for secrets, credentials, machine-specific paths.
4. From the repo root, run `./install.sh` (or `stow -R <package>` for just one).
5. `git status`, review, stage, commit.

## Adding a New Package

1. Create the package directory at the repo root: `mkdir <pkg>`.
2. Populate it with files mirroring the `$HOME` subtree (leading dots preserved).
3. Add the package name to the `stow` invocation in `install.sh`.
4. Run `./install.sh`.

## Removing a Tracked File

1. `git rm <pkg>/<path>`.
2. `stow -R <pkg>` from the repo root. `--restow` re-evaluates the package and removes the now-orphaned symlink in `$HOME`.

## Removing a Package

1. `stow -D <pkg>` to delete its symlinks from `$HOME`.
2. Remove the package name from `install.sh`.
3. `git rm -r <pkg>`.

## Conflict Resolution

If stow refuses to install with a "conflict" message, the target path in `$HOME` is a real file (not a symlink, or the wrong symlink). Move it aside (`mv ~/.foo ~/.foo.bak`) and rerun. Never let stow clobber unknown content.

`stow -nv <pkg>` performs a dry run and shows what would change without touching anything.

## What Not to Track

- Auth files, session files, sqlite databases, plugin binaries, caches, logs.
- `*.pem`, `*.key`, `id_*`, `.env*`, `.zshrc.local` (already gitignored).
- The top-level `AGENTS.md` written by tools (`AGENTS.md` is gitignored except `!/AGENTS.md`, which whitelists the human-authored one at the repo root).
- Per-machine settings that diverge between hosts.

The codex package keeps its own `.codex/.gitignore` with an *allowlist* pattern — runtime files dropped into the repo by tools are excluded by default.

## Quick Verification

```sh
./install.sh                        # idempotent — should print nothing surprising
stow -nv -R zsh nvim ghostty codex agents claude   # dry-run preview
git status                          # any unexpected dirty state?
```
