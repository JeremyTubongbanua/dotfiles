# dotfiles

My macOS development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/). The main workflow is Ghostty, Herdr, Neovim, and the Pi and Claude Code coding agents.

## Daily Workflow

| Tool | Role | Configuration |
|------|------|---------------|
| [Ghostty](https://ghostty.org/) | Terminal emulator | Fira Code, automatic Catppuccin light and dark themes, transparent background, and split navigation |
| [Herdr](https://herdr.dev/) | Workspace and agent multiplexer | Vim-style workspace navigation, agent labels, and a custom project launcher |
| [Neovim](https://neovim.io/) | Editor | Native LSP, Treesitter, Snacks picker, Oil, Harpoon, Fugitive, and mini.diff |
| [Pi](https://pi.dev/) | AI coding agent | OpenAI Codex and Claude models, Figma and Playwright MCP, web access, and custom extensions |
| [Claude Code](https://claude.com/product/claude-code) | AI coding agent | `claude` and `claude-work` accounts, shared skills, status line, and Catppuccin themes |
| [Codex](https://github.com/openai/codex) | AI coding agent | Sandboxed permission profile, network allowlist, and Figma MCP |
| [Beads](https://github.com/gastownhall/beads) | Agent issue tracker and memory | `bd` CLI from Homebrew |

Ghostty hosts Herdr, and Herdr organizes each project into four tabs:

1. `zsh` for the shell
2. `nvim` for the editor
3. `pi` for the Pi agent
4. `claude-work` for Claude Code

In Herdr, `Ctrl+b` followed by `Shift+m` opens the custom workspace launcher. It prompts for a directory and workspace name, then creates the four-tab layout. `zsh/.zshrc` starts `nvim`, `pi`, or `claude-work` in a new tab with that label.

For an existing directory, the launcher performs no Git operations. For a new directory inside a detected worktree collection, it prunes and updates the sibling `trunk`, hard-resets it to `upstream/trunk` or `origin/trunk`, and creates a worktree for the requested branch.

Agents use the same launcher through the `herdr-delegate` skill to hand a task to a new workspace instead of working on it themselves. `new-workspace.zsh --agent <pi|claude-work> <dir> [<name>]` reads the task from stdin, builds the workspace without taking focus, refuses to reset a `trunk` with uncommitted changes, and starts that agent with the task as its first prompt.

The `new-workspace` skill lets an agent open a workspace the way the popup does, with no task attached. `new-workspace.zsh --open <dir> [<name>]` skips the prompts, focuses the new workspace, and also refuses to reset a `trunk` with uncommitted changes.

Relevant files:

| File | Purpose |
|------|---------|
| `ghostty/.config/ghostty/config` | Terminal appearance, shell integration, clipboard bindings, and split navigation |
| `herdr/.config/herdr/config.toml` | Workspace keys, labels, theme, and launcher binding |
| `herdr/.config/herdr/new-workspace.zsh` | Project workspace and Git worktree creation |
| `nvim/.config/nvim/` | Editor configuration and plugin definitions |
| `nvim/.config/nvim/README.md` | Neovim notes, keymaps, and plugin usage |
| `pi/.pi/agent/settings.json` | Pi models, packages, skills, and extensions |
| `pi/.pi/agent/mcp-adapter.json` | Pi MCP server configuration |
| `claude/.claude-work/settings.json` | Claude Code permissions, hooks, plugins, and model |
| `agents/.agents/AGENTS.md` | Shared agent instructions, linked as each agent's `CLAUDE.md` or `AGENTS.md` |
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
stow --target "$HOME" --restow agents brew claude codex docker dockerfiles gh ghostty git herdr linearmouse nvim pi scripts vorssaint zsh
```

To restow only the core terminal workflow:

```sh
stow --target "$HOME" --restow ghostty herdr nvim pi claude zsh
```

Stow refuses to overwrite a real file or an unexpected symlink. Preview changes before resolving a conflict:

```sh
stow --target "$HOME" --simulate --verbose --restow ghostty herdr nvim pi claude zsh
```

## Packages

Each top-level package mirrors the path it owns under `$HOME`.

| Package | Installed path |
|---------|----------------|
| `agents` | `~/.agents/` |
| `brew` | `~/Brewfile` |
| `claude` | `~/.claude/` and `~/.claude-work/` |
| `codex` | `~/.codex/` |
| `docker` | `~/.docker/daemon.json` |
| `dockerfiles` | `~/.dockerfiles/` |
| `gh` | `~/.config/gh/config.yml` |
| `ghostty` | `~/.config/ghostty/` |
| `git` | `~/.gitconfig` |
| `herdr` | `~/.config/herdr/` |
| `linearmouse` | `~/.config/linearmouse/linearmouse.json` |
| `nvim` | `~/.config/nvim/` |
| `pi` | `~/.pi/agent/` and `~/.pi-lens/config.json` |
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
stow --target "$HOME" --simulate --verbose --restow agents brew claude codex docker dockerfiles gh ghostty git herdr linearmouse nvim pi scripts vorssaint zsh
```

Remove one package's managed links:

```sh
stow --target "$HOME" --delete <package>
```
