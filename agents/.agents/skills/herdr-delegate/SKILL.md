---
name: herdr-delegate
description: Hand a task to a fresh claude-work or pi agent in a new herdr workspace, usually on a new git worktree and branch, instead of doing it in this session. Use when the user asks to open or spin up a new herdr workspace, worktree, or branch for a task, or to hand a task off to another workspace or agent.
argument-hint: <task>
---

# Delegate a Task to a New Herdr Workspace

This session only sets up and hands off. The task runs in the new workspace's agent tab so this session stays free. Do not start the task here, not even its exploration.

## Choose the Directory

- **Worktree collection.** The repository lives in a folder holding a `trunk` checkout, such as `~/GitHub/atsign/noports/trunk`. The new worktree is `<collection>/<branch>`, and the branch is that path relative to the collection, so `~/GitHub/atsign/noports/jt/fix-relay` becomes branch `jt/fix-relay`. Use `jt/<short-kebab-name>` unless the user names a branch. If the directory already exists, the workspace opens there with no git work.
- **Plain checkout.** With no `trunk` sibling, create the worktree the user asked for yourself with `git -C <repo> worktree add -b <branch> <path>`, placing `<path>` beside the repository, then pass that directory.
- **No new worktree wanted.** Pass the existing directory.

## Choose the Agent

Use the agent the user names. Otherwise use `pi` when this session is pi, and `claude-work` in every other case.

## Write the Brief

The new agent sees none of this conversation, so the brief must stand on its own:

- the goal and why it matters
- the directory and branch it is working in
- everything from this conversation that bears on the task, such as decisions, constraints, links, issue IDs, file paths, and error output
- what is already known or ruled out
- what done looks like and how to verify it

Do not ask it to commit, push, or open a pull request unless the user asked for that.

## Dispatch

Run the herdr launcher with the brief on stdin, as one command:

```sh
~/.config/herdr/new-workspace.zsh --agent <claude-work|pi> <dir> [<workspace name>] <<'EOF'
<brief>
EOF
```

For a new directory in a worktree collection, it prunes and fetches `trunk`, resets it to `upstream/trunk` or `origin/trunk`, and adds the worktree. It then opens the usual `zsh`, `nvim`, `pi`, and `claude-work` tabs without taking the user's focus and starts the chosen agent with the brief. The workspace name defaults to the branch name.

It refuses to reset a `trunk` with uncommitted changes. If that or anything else fails, report the error and stop. Never fall back to doing the task in this session.

## Report

Give the workspace name, directory, branch, agent, and a one-line summary of the brief, then stop. Mention that a folder Claude has never opened may show its trust prompt in that tab. Do not wait on the agent or read its output unless asked. When asked, find its pane with `herdr agent list` and read it with `herdr agent read <pane-id> --source recent-unwrapped --lines 80`.
