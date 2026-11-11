# dotfiles

My macOS development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/). The main workflow is Ghostty, Herdr, Neovim, and Claude Code.

## Daily Workflow

| Tool | Role | Configuration |
|------|------|---------------|
| [Ghostty](https://ghostty.org/) | Terminal emulator | Fira Code, automatic Catppuccin light and dark themes, transparent background, and split navigation |
| [Herdr](https://herdr.dev/) | Workspace and agent multiplexer | Vim-style workspace navigation, agent labels, and a custom project launcher |
| [Neovim](https://neovim.io/) | Editor | Native LSP, Treesitter, Snacks picker, Oil, Harpoon, Fugitive, and mini.diff |
| [Claude Code](https://claude.com/product/claude-code) | AI coding agent | Shared skills, status line, and Catppuccin themes |
| [Codex](https://github.com/openai/codex) | AI coding agent | Sandboxed permission profile, network allowlist, and Figma MCP |

Ghostty hosts Herdr, and Herdr organizes each project into three tabs:

1. `zsh` for the shell
2. `nvim` for the editor
3. `claude` for Claude Code

In Herdr, `Ctrl+b` followed by `Shift+m` opens the custom workspace launcher. It prompts for a directory and workspace name, then creates the three-tab layout. `zsh/.zshrc` starts `nvim` or `claude` in a new tab with that label.

For an existing directory, the launcher performs no Git operations. For a new directory inside a detected worktree collection, it prunes and updates the sibling `trunk`, hard-resets it to `upstream/trunk` or `origin/trunk`, and creates a worktree for the requested branch.

Agents use the same launcher through the `herdr-delegate` skill to hand a task to a new workspace instead of working on it themselves. `new-workspace.zsh --agent <dir> [<name>]` reads the task from stdin, builds the workspace without taking focus, refuses to reset a `trunk` with uncommitted changes, and starts Claude Code with the task as its first prompt.

The `new-workspace` skill lets an agent open a workspace the way the popup does, with no task attached. `new-workspace.zsh --open <dir> [<name>]` skips the prompts, focuses the new workspace, and also refuses to reset a `trunk` with uncommitted changes.

The `review-daemon` skill watches GitHub for pull requests that request my review or are assigned to me, from a `review daemon` tab in the current workspace, so closing the workspace stops it. Each new one gets its own tab in the watching session's workspace, named after the project, such as `atsign claude` or `align claude`, where Claude runs `/code-review` and then asks in that tab whether to post the review. The watching session only orchestrates and summarises what each review tab is doing. Its state lives in `~/.local/state/review-daemon/`.

Relevant files:

| File | Purpose |
|------|---------|
| `ghostty/.config/ghostty/config` | Terminal appearance, shell integration, clipboard bindings, and split navigation |
| `herdr/.config/herdr/config.toml` | Workspace keys, labels, theme, and launcher binding |
| `herdr/.config/herdr/new-workspace.zsh` | Project workspace and Git worktree creation |
| `nvim/.config/nvim/` | Editor configuration and plugin definitions |
| `nvim/.config/nvim/README.md` | Neovim notes, keymaps, and plugin usage |
| `claude/.claude/settings.json` | Claude Code permissions, hooks, plugins, and model |
| `agents/.agents/AGENTS.md` | Shared agent instructions, linked as Claude Code's `CLAUDE.md` and Codex's `AGENTS.md` |
| `agents/.agents/skills/` | Shared agent skills |
| `zsh/.zshrc` | Agent shell functions and Herdr tab autostart |

## Install

Run these commands from the repository root.

Install the tracked Homebrew formulae and applications:

```sh
brew bundle --file brew/Brewfile
```

Install or repair every dotfiles package:

```sh
stow --target "$HOME" --restow agents brew claude codex docker dockerfiles gh ghostty git herdr linearmouse nvim rectangle scripts vorssaint zsh
```

To restow only the core terminal workflow:

```sh
stow --target "$HOME" --restow ghostty herdr nvim claude zsh
```

Stow refuses to overwrite a real file or an unexpected symlink. Preview changes before resolving a conflict:

```sh
stow --target "$HOME" --simulate --verbose --restow ghostty herdr nvim claude zsh
```

## Packages

Each top-level package mirrors the path it owns under `$HOME`.

| Package | Installed path |
|---------|----------------|
| `agents` | `~/.agents/` |
| `brew` | `~/Brewfile` |
| `claude` | `~/.claude/` |
| `codex` | `~/.codex/` |
| `docker` | `~/.docker/daemon.json` |
| `dockerfiles` | `~/.dockerfiles/` |
| `gh` | `~/.config/gh/config.yml` |
| `ghostty` | `~/.config/ghostty/` |
| `git` | `~/.gitconfig` |
| `herdr` | `~/.config/herdr/` |
| `linearmouse` | `~/.config/linearmouse/linearmouse.json` |
| `nvim` | `~/.config/nvim/` |
| `rectangle` | `~/RectangleConfig.json` |
| `scripts` | `~/.scripts/` |
| `vorssaint` | `~/Vorssaint Settings.plist` |
| `zsh` | `~/.zshrc` and `~/.config/spaceship.zsh` |

## Maintenance

Refresh `brew/Brewfile` from the currently installed Homebrew packages:

```sh
./update-brewfile.sh
```

Preview every package:

```sh
stow --target "$HOME" --simulate --verbose --restow agents brew claude codex docker dockerfiles gh ghostty git herdr linearmouse nvim rectangle scripts vorssaint zsh
```

Remove one package's managed links:

```sh
stow --target "$HOME" --delete <package>
```
