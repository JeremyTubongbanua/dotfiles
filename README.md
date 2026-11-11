# dotfiles

My macOS development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/). The main workflow is Ghostty, Herdr, Neovim, and Claude Code.

It mirrors my 14-inch MacBook Pro (2026, `Mac18,1`) with an Apple M6 chip, 32 GB of memory, and a 1 TB SSD.

## Daily Workflow

| Tool | Role | Configuration |
|------|------|---------------|
| [Ghostty](https://ghostty.org/) | Terminal emulator | Fira Code, automatic Catppuccin light and dark themes, transparent background, and split navigation |
| [Herdr](https://herdr.dev/) | Workspace and agent multiplexer | Vim-style workspace navigation, agent labels, and a custom project launcher |
| [Neovim](https://neovim.io/) | Editor | Native LSP, Treesitter, Snacks picker, Oil, Harpoon, Fugitive, and mini.diff |
| [Claude Code](https://claude.com/product/claude-code) | AI coding agent | Shared skills, status line, and Catppuccin themes |

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
| `agents/.agents/AGENTS.md` | Shared agent instructions, linked as Claude Code's `CLAUDE.md` |
| `agents/.agents/skills/` | Shared agent skills |
| `zsh/.zshrc` | Agent shell functions and Herdr tab autostart |

## Install

Run these commands from the repository root.

Install the tracked Homebrew formulae and applications:

```sh
brew bundle --file brew/Brewfile
```

Install oh-my-zsh, which `zsh/.zshrc` loads, without letting it replace `.zshrc`:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
```

Install or repair every dotfiles package:

```sh
stow --target "$HOME" --restow agents brew claude gh ghostty git herdr linearmouse nvim rectangle scripts vorssaint zsh
```

To restow only the core terminal workflow:

```sh
stow --target "$HOME" --restow ghostty herdr nvim claude zsh
```

Stow refuses to overwrite a real file or an unexpected symlink. Preview changes before resolving a conflict:

```sh
stow --target "$HOME" --simulate --verbose --restow ghostty herdr nvim claude zsh
```

Install the tools that live outside Homebrew. uv lands in `~/.local/bin`, and `at_activate_web` lands in `~/.pub-cache/bin`, both of which `zsh/.zshrc` adds to `PATH`:

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
dart pub global activate at_activate_web
```

`claude/.claude/settings.json` enables the claude-mem plugin from the `thedotmack` marketplace. If Claude Code does not install it on its own, run `/plugin install claude-mem@thedotmack` inside Claude Code. The plugin puts its `claude-mem` worker in `~/.local/bin`.

Add the Playwright MCP server, which Claude Code keeps in `~/.claude.json` rather than in a tracked file:

```sh
claude mcp add --scope user playwright -- npx @playwright/mcp@latest
```

Apply the macOS settings: fast key repeat, an auto-hiding Dock, hot corners, Finder list view with path and status bars, screenshots to the clipboard, and no edge-drag window tiling, since Rectangle handles that. Log out and back in for key repeat to take effect:

```sh
./macos-defaults.sh
```

LinearMouse reads `~/.config/linearmouse/linearmouse.json` directly, so it picks up the linked config on launch. Rectangle keeps its live settings in its own preferences instead, so load `rectangle/RectangleConfig.json` once: copy it to `~/Library/Application Support/Rectangle/RectangleConfig.json` before launching Rectangle, which imports it and renames the copy, or use Import in Rectangle's settings.

## Packages

Each top-level package mirrors the path it owns under `$HOME`.

| Package | Installed path |
|---------|----------------|
| `agents` | `~/.agents/` |
| `brew` | `~/Brewfile` |
| `claude` | `~/.claude/` |
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

LinearMouse saves straight into `linearmouse/.config/linearmouse/linearmouse.json`, so its changes show up in `git status` on their own. After changing Rectangle settings, use Export in Rectangle's settings and save over `rectangle/RectangleConfig.json`.

Preview every package:

```sh
stow --target "$HOME" --simulate --verbose --restow agents brew claude gh ghostty git herdr linearmouse nvim rectangle scripts vorssaint zsh
```

Remove one package's managed links:

```sh
stow --target "$HOME" --delete <package>
```
