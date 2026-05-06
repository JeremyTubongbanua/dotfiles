# dotfiles

My personal dotfiles

<!-- DOTFILES_TOC_START -->
## Dotfiles In Place

Run `scripts/update-readme-dotfiles.sh` to refresh this generated section.

| Home path | Repo path | Purpose |
| --- | --- | --- |
| `~/.zshrc` | `dot/zshrc` | Zsh shell configuration |
| `~/.config/nvim` | `dot/config/nvim` | Neovim configuration directory |
| `~/.config/ghostty` | `dot/config/ghostty` | Ghostty terminal configuration directory |
| `~/.codex/AGENTS.md` | `dot/codex/AGENTS.md` | Codex instructions |
| `~/.codex/config.toml` | `dot/codex/config.toml` | Codex user configuration |
| `~/.codex/agents` | `dot/codex/agents` | Codex sub-agent definitions |
| `~/.codex/rules/default.rules` | `dot/codex/rules/default.rules` | Codex default rules |
| `~/.agents` | `dot/agents` | Agents skills and lock file |
| `~/.pi/agent/AGENTS.md` | `dot/pi/agent/AGENTS.md` | Pi agent instructions |
| `~/.pi/agent/settings.json` | `dot/pi/agent/settings.json` | Pi agent settings |
| `~/.pi/agent/agents` | `dot/pi/agent/agents` | Pi agent sub-agent definitions |
| `~/.pi/agent/skills` | `dot/pi/agent/skills` | Pi agent skills |
| `~/.pi/agent/extensions` | `dot/pi/agent/extensions` | Pi agent extensions |
| `~/.claude/CLAUDE.md` | `dot/claude/CLAUDE.md` | Claude Code global instructions |
| `~/.claude/settings.json` | `dot/claude/settings.json` | Claude Code user settings |
| `~/.claude/agents` | `dot/claude/agents` | Claude Code custom subagents |
<!-- DOTFILES_TOC_END -->

## Activation

Run the install script to link tracked home files and folders into this repo:

```sh
./install.sh
```

After activation, editing any linked path in `$HOME` (see the table above)
changes the tracked repo file directly through the symlink. Then review with
`git status` and use `git add` and `git commit` yourself.

The script only links the specific files and folders listed in the table. It
does not link entire parent directories such as `~/.codex` or `~/.pi/agent`,
so local auth, logs, caches, memories, sessions, and other runtime state stay
outside git.

The installer also links `scripts/pre-commit` into `.git/hooks/pre-commit`.
That hook checks this README inventory before each commit, refreshes it when it
is stale, and stops the commit so you can review and stage the README yourself.

## Tracking Future Files

This repo mirrors files from my home directory using paths relative to `$HOME`.
Actual hidden files and folders live under `dot/`, with the leading `.` removed.
For example, `~/.zshrc` is tracked here as `dot/zshrc`, `~/.codex` is tracked
here as `dot/codex/`, and `~/.config/nvim/init.lua` is tracked here as
`dot/config/nvim/init.lua`.

To add a new file:

1. Create the matching folder path in this repo.
2. If the source path starts with `.`, place it under `dot/` and remove that
   leading dot in the repo path.
3. Copy the file into that path.
4. Review the file for secrets, credentials, machine-specific paths, and other
   private values before tracking it.
5. Run a quick smoke check for the tool the file configures.
6. Review the diff with `git diff`.

Example:

```sh
mkdir -p dot/config/example
cp ~/.config/example/settings.toml dot/config/example/settings.toml
git diff -- dot/config/example/settings.toml
```

When adding a top-level hidden file or folder, track it under `dot/` without
the leading dot. For example, files from `~/.codex` should go under
`dot/codex/`, and `~/.zshrc` should be tracked as `dot/zshrc`.

Do not track generated caches, local state, package installs, or secret files.
Prefer documenting how to recreate those files instead.
