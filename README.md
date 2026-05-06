# dotfiles

My personal dotfiles. Tracked files are symlinked from `$HOME` into `dot/`, so editing the file in either place edits the same inode.

## Layout

```
dot/        — tracked configs, mirroring $HOME with leading dots stripped
              (e.g. ~/.zshrc → dot/zshrc, ~/.codex/ → dot/codex/)
scripts/    — install helpers and the pre-commit hook
install.sh  — symlinks tracked paths into $HOME and installs the pre-commit hook
AGENTS.md   — operational guide for AI agents working in this repo
```

## Install

```sh
./install.sh
```

Existing files at the target paths are backed up to `~/.dotfiles-backup/<timestamp>/` before symlinks replace them.

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

## Adding or Changing Tracked Files

See [AGENTS.md](AGENTS.md) for the full procedure. Short version: copy the source into the matching `dot/` path, add a `link_path` line in `install.sh`, add a case to `scripts/update-readme-dotfiles.sh`, then run `./install.sh`.
