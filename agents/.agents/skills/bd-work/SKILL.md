---
name: bd-work
description: Work one beads issue end to end, claiming, implementing, verifying, and closing it. Use when started as a worker by /bd-next, when the user runs /bd-work <id>, or when asked to work a specific beads issue in this session.
argument-hint: <issue id>
---

# Work a Beads Issue

Complete exactly one issue, then stop. Usually an orchestrator session started you with `/bd-next`, in your own herdr tab labelled with the issue ID.

## Pick Up the Issue

Use the issue ID in `$ARGUMENTS`. If it is empty, take the top result of `bd ready --exclude-type epic`, and if nothing is ready, say so and stop.

Run `bd show <id>`. Read its description, design notes, and acceptance criteria, the parent epic, and the close reasons of the issues it depended on. When the issue or its epic has a `spec_id`, read the relevant part of that plan file.

Claim it with `bd update <id> --claim`. The orchestrator usually claimed it already as the same user, which is fine. If another actor holds it, stop and say so.

## Implement

Implement only what the acceptance criteria require, following the user's and repository's instructions. Other workers may be running in sibling tabs on the same working tree, so keep changes to the files this issue needs.

When you find work outside the issue's scope, such as a bug, a follow-up, or a missing test, file it instead of doing it:

```sh
bd create "<title>" -t <type> -p <priority> -d "<what and why>" \
  --deps discovered-from:<id>
```

If that new work blocks the current issue, link it with `bd dep add <id> <new-id>`, record progress with `bd update <id> --append-notes "<what is done, what is left>"`, run `bd unclaim <id>`, and stop to tell the user.

## Verify and Close

Run the checks that prove the acceptance criteria: tests, analyzers, a build, or a screenshot for UI work. If verification fails and the fix is out of scope, leave the issue in progress, append notes explaining what is left, and stop.

Once verified, close it:

```sh
bd close <id> --reason "<what changed and how it was verified>" --suggest-next
```

If that closed the last open child of an epic, close the epic too.

## Report

Give the issue ID and title, what changed as `path/to/file.ext:line` references, how it was verified, any issues filed along the way, and what became ready. Then stay idle in this tab for follow-up questions; do not start another issue or close the tab.
