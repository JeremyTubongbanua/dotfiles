---
name: new-workspace
description: Open a new herdr workspace the way herdr's prefix+shift+m new-workspace popup does, from a directory or branch name, creating the git worktree from a freshly reset trunk when needed, then opening and focusing its zsh, nvim, pi, and claude-work tabs. Use when the user runs /new-workspace or asks to open, create, or spin up a herdr workspace, worktree, or branch without handing it a task.
argument-hint: <dir | branch> [workspace name]
---

# Open a New Herdr Workspace

Do what the `prefix+shift+m` popup does, without its prompts, using the same launcher.

If the request also gives the new workspace a task, use the `herdr-delegate` skill instead, so an agent in that workspace does the task.

## Choose the Directory

Work out the directory from `$ARGUMENTS`. If it is empty, ask which directory or branch to open.

- **A path:** use it as given, expanding `~`.
- **A branch inside a worktree collection:** a collection is a folder holding a `trunk` checkout, such as `~/GitHub/atsign/noports/trunk`. Find this repository's collection with `git rev-parse --path-format=absolute --git-common-dir`; when that returns `<collection>/trunk/.git`, the directory is `<collection>/<branch>`, so branch `jt/fix-relay` becomes `~/GitHub/atsign/noports/jt/fix-relay`.
- **A short description instead of a branch:** name the branch `jt/<short-kebab-name>`.
- **A branch in a plain checkout with no `trunk`:** create the worktree yourself with `git -C <repo> worktree add -b <branch> <path>`, placing `<path>` beside the repository, then open that directory.

The workspace name is the second argument when given. Otherwise leave it out, and the launcher names it after the branch inside a collection, or after the directory's last path component.

## Open It

Run the launcher as one command:

```sh
~/.config/herdr/new-workspace.zsh --open <dir> [<workspace name>]
```

It behaves like the popup:

- An existing directory opens as is, with no git work.
- A new directory inside a worktree collection gets a worktree. The launcher prunes and fetches `trunk`, hard-resets it to `upstream/trunk` or `origin/trunk`, then checks out the branch: the local branch if it exists, the remote branch if only that exists, or a new branch from trunk.
- Any other new directory is created empty.
- The workspace gets `zsh`, `nvim`, `pi`, and `claude-work` tabs and takes focus on its `zsh` tab.

Unlike the popup, it refuses to reset a `trunk` with uncommitted changes. If that or anything else fails, report the error and stop. Never stash, discard, or commit changes in `trunk` to get past it.

## Report

Give the workspace name, directory, and branch in one or two lines, and mention that the new workspace now has focus. A folder Claude has never opened may show its trust prompt in the `claude-work` tab.
