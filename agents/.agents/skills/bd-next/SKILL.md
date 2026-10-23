---
name: bd-next
description: Dispatch the next ready beads issue to a new worker agent in an adjacent herdr tab, keeping this session free to plan and orchestrate. Use when the user runs /bd-next or asks to hand beads work off to agents.
argument-hint: [issue id | epic id | label | count]
---

# Dispatch the Next Beads Issue

This session is the orchestrator. It chooses work and hands each issue to a worker agent in its own herdr tab; it does not implement issues itself.

## Choose the Issues

- If `$ARGUMENTS` is an issue ID, use it. If it is an epic, take the top result of `bd ready --parent <epic-id> --exclude-type epic`.
- If `$ARGUMENTS` is a label, take the top result of `bd ready --label <label> --exclude-type epic`.
- If `$ARGUMENTS` is a number N, take up to N issues from `bd ready --exclude-type epic`. Every worker shares this working tree, so pick only issues that are unlikely to edit the same files, and say which ready issues you held back and why.
- Otherwise take the top result of `bd ready --exclude-type epic`.
- If nothing is ready, say so, show `bd blocked`, and stop.

## Dispatch

For each chosen issue:

1. Claim it with `bd update <id> --claim` so the next `/bd-next` skips it. If another actor already holds it, skip it.
2. Run `bd-dispatch <id>`. It opens a tab labelled with the issue ID directly after this session's tab, in the same herdr workspace and directory, and starts a worker running `/bd-work <id>` with the same Claude profile as this session. It does not change the user's focus.
3. If `bd-dispatch` fails, for example because this session is not inside herdr, run `bd unclaim <id>` and tell the user to run `/bd-work <id>` in another session.

## Report

List each dispatched issue's ID, title, and tab, then return to the user. Do not wait on workers or read their output unless asked. When asked, check them with `herdr agent list` and `herdr agent read <pane-id> --source recent-unwrapped --lines 80`, and see results with `bd show <id>` or `bd ready`.
