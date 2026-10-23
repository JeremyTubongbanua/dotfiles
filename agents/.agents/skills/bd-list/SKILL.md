---
name: bd-list
description: Show this repository's beads issues grouped by status, with the state of each in-progress issue's worker subagent. Use when the user runs /bd-list or asks what is in the beads queue, what the workers are doing, or what is left.
argument-hint: [closed | all | epic id | label | search text]
---

# List Beads Issues

This is read-only. Never create, claim, update, or close issues here.

## Gather

With no `$ARGUMENTS`, collect an overview:

- Every issue that is not closed: `bd list --status open,in_progress,blocked,deferred --json --brief`
- What `/bd-next` would dispatch, in order: `bd ready --exclude-type epic`
- What blocks the rest: `bd blocked`
- Issues closed since yesterday: `bd list --status closed --closed-after <yesterday as YYYY-MM-DD>`
- The worker subagents this session dispatched with `/bd-next`, and whether each is still running or has finished.

With `$ARGUMENTS`, narrow it instead:

- `closed`: `bd list --status closed --sort closed`
- `all`: `bd list --all`
- An epic ID: `bd list --parent <id>` and `bd graph <id> --compact`
- A label: `bd list --label <label>`
- Anything else: `bd search "<text>"`

## Present

Show one compact table per section, in this order, skipping empty sections:

1. **In progress:** ID, title, priority, and worker state: "running", "finished, issue still open", or "no worker in this session".
2. **Ready:** ID, title, priority, and type in `bd ready` order, marking the one `/bd-next` would dispatch first.
3. **Blocked:** ID, title, and the issues blocking it.
4. **Deferred:** ID, title, and when it wakes.
5. **Closed since yesterday:** ID, title, and close reason.

End with one line of counts per status. Then flag anything that needs the user: a worker that finished but left its issue in progress, and an in-progress issue with no worker in this session, which may be abandoned and can be released with `bd unclaim <id>`.
