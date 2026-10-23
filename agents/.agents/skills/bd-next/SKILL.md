---
name: bd-next
description: Dispatch the next ready beads issue to a worker subagent, keeping this session free to plan and orchestrate. Use when the user runs /bd-next or asks to hand beads work off to agents.
argument-hint: [issue id | epic id | label | count]
---

# Dispatch the Next Beads Issue

This session is the orchestrator. It chooses work and hands each issue to a worker subagent; it does not implement issues itself.

## Choose the Issues

- If `$ARGUMENTS` is an issue ID, use it. If it is an epic, take the top result of `bd ready --parent <epic-id> --exclude-type epic`.
- If `$ARGUMENTS` is a label, take the top result of `bd ready --label <label> --exclude-type epic`.
- If `$ARGUMENTS` is a number N, take up to N issues from `bd ready --exclude-type epic`. Every worker shares this working tree, so pick only issues that are unlikely to edit the same files, and say which ready issues you held back and why.
- Otherwise take the top result of `bd ready --exclude-type epic`.
- If nothing is ready, say so, show `bd blocked`, and stop.

## Dispatch

For each chosen issue:

1. Claim it with `bd update <id> --claim` so the next `/bd-next` skips it. If another actor already holds it, skip it.
2. Start a subagent in the background whose prompt is to work issue `<id>` by following the `bd-work` skill and to end with that skill's report. Start every chosen issue's subagent at once so they run in parallel.
3. If a subagent cannot be started, run `bd unclaim <id>` and tell the user.

## Report

List each dispatched issue's ID and title, then return to the user without waiting. As each worker finishes, relay its report: what changed, how it was verified, issues it filed, and what became ready. If a worker stopped with its issue still in progress, say what is left according to `bd show <id>`. Do not dispatch more work unless the user asks.
