# dotfiles

My macOS development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/). The main workflow is Ghostty, Herdr, Neovim, and Oh My Pi (OMP).

## Daily Workflow

| Tool | Role | Configuration |
|------|------|---------------|
| [Ghostty](https://ghostty.org/) | Terminal emulator | Fira Code, automatic Catppuccin light and dark themes, transparent background, and split navigation |
| [Herdr](https://herdr.dev/) | Workspace and agent multiplexer | Vim-style workspace navigation, agent labels, and a custom project launcher |
| [Neovim](https://neovim.io/) | Editor | Native LSP, Treesitter, Snacks picker, Oil, Harpoon, Fugitive, and mini.diff |
| [OMP](https://github.com/can1357/oh-my-pi) | AI coding agent | OpenAI Codex and Claude providers, web search, Figma MCP, and hashline editing |

Ghostty hosts Herdr, and Herdr organizes each project into three tabs:

1. `zsh` for the shell
2. `nvim` for the editor
3. `omp` for the coding agent

In Herdr, `Ctrl+b` followed by `Shift+m` opens the custom workspace launcher. It prompts for a directory and workspace name, then creates the three-tab layout.

For an existing directory, the launcher performs no Git operations. For a new directory inside a detected worktree collection, it prunes and updates the sibling `trunk`, hard-resets it to `upstream/trunk` or `origin/trunk`, and creates a worktree for the requested branch.

Relevant files:

| File | Purpose |
|------|---------|
| `ghostty/.config/ghostty/config` | Terminal appearance, shell integration, clipboard bindings, and split navigation |
| `herdr/.config/herdr/config.toml` | Workspace keys, labels, theme, and launcher binding |
| `herdr/.config/herdr/new-workspace.zsh` | Project workspace and Git worktree creation |
| `nvim/.config/nvim/` | Editor configuration and plugin definitions |
| `nvim/.config/nvim/README.md` | Neovim notes, keymaps, and plugin usage |
| `omp/.omp/agent/config.yml` | Models, providers, interface, tools, and agent behavior |
| `omp/.omp/agent/mcp.json` | MCP server configuration |

## Install

Run these commands from the repository root.

Install the tracked Homebrew formulae and applications:

```sh
brew bundle --file brew/Brewfile
```

Install or repair every dotfiles package:

```sh
stow --target "$HOME" --restow agents brew claude claude-work codex docker dockerfiles gh ghostty git herdr linearmouse nvim omp pi scripts vorssaint zsh
```

To restow only the core terminal workflow:

```sh
stow --target "$HOME" --restow ghostty herdr nvim omp
```

Stow refuses to overwrite a real file or an unexpected symlink. Preview changes before resolving a conflict:

```sh
stow --target "$HOME" --simulate --verbose --restow ghostty herdr nvim omp
```

## Packages

Each top-level package mirrors the path it owns under `$HOME`.

| Package | Installed path |
|---------|----------------|
| `agents` | `~/.agents/` |
| `brew` | `~/Brewfile` |
| `claude` | `~/.claude/` |
| `claude-work` | `~/.claude-work/` |
| `codex` | `~/.codex/` |
| `docker` | `~/.docker/daemon.json` |
| `dockerfiles` | `~/.dockerfiles/` |
| `gh` | `~/.config/gh/config.yml` |
| `ghostty` | `~/.config/ghostty/` |
| `git` | `~/.gitconfig` |
| `herdr` | `~/.config/herdr/` |
| `linearmouse` | `~/.config/linearmouse/linearmouse.json` |
| `nvim` | `~/.config/nvim/` |
| `omp` | `~/.omp/agent/` |
| `pi` | `~/.pi/agent/`, `~/.pi/web-search.json`, and `~/.pi-lens/config.json` |
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
stow --target "$HOME" --simulate --verbose --restow agents brew claude claude-work codex docker dockerfiles gh ghostty git herdr linearmouse nvim omp pi scripts vorssaint zsh
```

Remove one package's managed links:

```sh
stow --target "$HOME" --delete <package>
```

See [AGENTS.md](AGENTS.md) for package conventions, adding or removing tracked files, tree folding, and conflict handling.
