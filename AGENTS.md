# Agent Guide

Operational instructions for AI agents working in this dotfiles repo. Humans should read `README.md` first.

## Repo Convention

This repo mirrors files from `$HOME` using paths relative to `$HOME` with leading dots stripped. Hidden files and folders live under `dot/`.

| Source in `$HOME`              | Path in repo                       |
| ------------------------------ | ---------------------------------- |
| `~/.zshrc`                     | `dot/zshrc`                        |
| `~/.codex/AGENTS.md`           | `dot/codex/AGENTS.md`              |
| `~/.config/nvim/init.lua`      | `dot/config/nvim/init.lua`         |

## Activation Mechanism

`install.sh` symlinks each tracked path from `$HOME` to its repo location using a shell function called `link_path`. Once activated, editing the file in either location edits the same inode — there is no copy or sync step.

**Critical invariant:** `install.sh` must use `link_path` (which calls `ln -s`). Two helper scripts grep `install.sh` for the literal token `link_path "$repo_dir/`:

- `scripts/update-readme-dotfiles.sh` — generates the README inventory table
- `scripts/check-dotfile-links.sh` — verifies each `$HOME` path is a symlink to the expected repo path

If you rename `link_path` or switch to copy semantics (`cp`, `rsync`), both helpers silently break and the next run overwrites live symlinks with stale copies, severing the home→repo connection. Don't do this.

When `install.sh` finds an existing non-symlink at a target path, it backs it up to `~/.dotfiles-backup/<timestamp>/` before linking.

## Adding a New Tracked File or Folder

1. Determine the repo path. Strip leading dots from any segment that has one. `~/.foo/bar.toml` → `dot/foo/bar.toml`.
2. Review the source for secrets, credentials, machine-specific paths, and runtime state. If you find any, do not track it — document the recreation steps instead.
3. Copy the source into the repo path: `mkdir -p dot/foo && cp -p ~/.foo/bar.toml dot/foo/bar.toml`.
4. Add a `link_path` line to `install.sh` (alongside the others, before `install_hook`):
   ```sh
   link_path "$repo_dir/dot/foo/bar.toml" "$HOME/.foo/bar.toml"
   ```
5. Add a `purpose_for` case to `scripts/update-readme-dotfiles.sh` so the README table gets a meaningful description instead of "Managed dotfile".
6. Run `./install.sh`. The original file in `$HOME` gets backed up; the new symlink replaces it.
7. Run `./scripts/check-dotfile-links.sh` to verify, then `./scripts/update-readme-dotfiles.sh` to refresh the inventory.
8. `git status`, review the diff, stage and commit.

## Removing a Tracked Path

1. Remove its `link_path` line from `install.sh`.
2. Remove its `purpose_for` case from `scripts/update-readme-dotfiles.sh`.
3. Delete the symlink in `$HOME` (`rm ~/.foo/bar.toml`) and restore a real file there if the user still needs it.
4. `git rm` the repo path and refresh the README.

## What Not to Track

- Generated caches, local state, package installs (e.g. `dot/config/nvim/pack/` is gitignored).
- Auth files, session files, binaries (e.g. `dot/pi/**/auth.json`, `dot/pi/**/sessions/`, `dot/pi/**/bin/`).
- Anything matching `*.pem`, `*.key`, `id_*`, `.env*`, `.zshrc.local` (already gitignored).
- Top-level `AGENTS.md` from tools that auto-write to it (gitignored except this file at the repo root and `dot/pi/agent/AGENTS.md`, which are explicitly whitelisted).
- Per-machine settings that diverge between hosts. Use `*.local` overlay files instead.

Always review for secrets before staging. The repo is public.

## Pre-Commit Hook

`install.sh` symlinks `scripts/pre-commit` into `.git/hooks/pre-commit`. The hook runs `check-dotfile-links.sh` (verifies live symlinks match `install.sh`) and `update-readme-dotfiles.sh --check` (verifies the README inventory is current). If the README is stale, it refreshes it and aborts the commit so the human can review and stage the change.

## Quick Verification

After any change to `install.sh`, the scripts, or tracked content:

```sh
./scripts/check-dotfile-links.sh   # all symlinks correct
./scripts/update-readme-dotfiles.sh --check && echo "README in sync"
git status
```
