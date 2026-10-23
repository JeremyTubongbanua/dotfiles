---
name: beads
description: Do anything with beads issue tracking from a plain-language request, so the user never has to remember a bd command. Covers setting beads up in a repository, listing what is open, ready, blocked, or closed, creating, updating, closing, reopening, and deleting issues, filing an approved plan as an epic, dispatching ready issues to worker subagents, and working one issue end to end. Use when the user runs /beads, mentions beads or bd, asks to file, track, list, change, close, or delete an issue or asks what is left, right after a plan is approved in a repository that uses beads, or when started as a worker on a beads issue.
argument-hint: [what you want, in plain words]
---

# Use Beads

Read `$ARGUMENTS`, together with the conversation, as a plain-language request, pick the matching action below, and run the `bd` commands yourself. The user should never need to know a `bd` command.

| The user wants to | Action | For example |
|---|---|---|
| See what is there. This is the default when `$ARGUMENTS` is empty. | [List](#list) | `/beads`, `list closed`, `what's left in dot-12` |
| Track new work | [Create](#create) | `add fix the login redirect`, `file a bug that ...` |
| Change an existing issue | [Update](#update) | `bump dot-4 to P1`, `dot-4 waits on dot-2`, `defer dot-7 to Monday` |
| Finish, drop, or bring back an issue | [Close](#close) | `close dot-4`, `dot-5 duplicates dot-3`, `reopen dot-4` |
| Erase an issue permanently | [Delete](#delete) | `delete dot-9` |
| File an approved plan | [Plan](#plan) | `plan`, or right after plan mode |
| Hand work to agents | [Next](#next) | `next`, `next 3`, `next dot-12` |
| Do one issue in this session | [Work](#work) | `work dot-4` |

Several actions in one request are fine; do them in order. If the request is ambiguous, or names an issue you cannot find with `bd search`, ask. For anything this skill does not cover, check `bd <command> --help` instead of guessing flags.

## Setup

These apply before every action:

- If `bd` reports no beads project here, ask before initializing, and initialize only with `bd init --stealth --skip-agents --role maintainer`. Never run `bd setup <tool>`, and never let beads add `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/`, or tracked `.beads/` files to the repository.
- If `bd` fails opening a routed store such as `~/.beads-planning`, the repository's role is `contributor`; fix it with `git config beads.role maintainer`.
- Never run `bd edit`; it opens an editor and blocks.

## List

This is read-only. Never create, claim, update, or close issues here.

With no `$ARGUMENTS`, collect an overview:

- Every issue that is not closed: `bd list --status open,in_progress,blocked,deferred --json --brief`
- What [Next](#next) would dispatch, in order: `bd ready --exclude-type epic`
- What blocks the rest: `bd blocked`
- Issues closed since yesterday: `bd list --status closed --closed-after <yesterday as YYYY-MM-DD>`
- The worker subagents this session dispatched, and whether each is still running or has finished.

Otherwise narrow it:

- Closed issues: `bd list --status closed --sort closed`
- Everything: `bd list --all`
- One issue: `bd show <id>`
- An epic: `bd list --parent <id>` and `bd graph <id> --compact`
- A label: `bd list --label <label>`
- Anything else: `bd search "<text>"`

Show one compact table per section, in this order, skipping empty sections:

1. **In progress:** ID, title, priority, and worker state: "running", "finished, issue still open", or "no worker in this session".
2. **Ready:** ID, title, priority, and type in `bd ready` order, marking the one [Next](#next) would dispatch first.
3. **Blocked:** ID, title, and the issues blocking it.
4. **Deferred:** ID, title, and when it wakes.
5. **Closed since yesterday:** ID, title, and close reason.

End with one line of counts per status. Then flag anything that needs the user: a worker that finished but left its issue in progress, and an in-progress issue with no worker in this session, which may be abandoned and can be released with `bd unclaim <id>`.

## Create

Turn the request into one well-formed issue per piece of work.

1. If the request does not say what the issue is, ask.
2. Run `bd search "<key words>"` to check for an open issue that already covers the same work. If one exists, show it and ask whether to update it instead of creating a duplicate.
3. Shape the issue:
   - **Title:** a short imperative phrase. Fix typos and capitalization, so "HOok up beads with Context7" becomes "Hook up beads with Context7".
   - **Type:** `bug`, `feature`, `task`, `chore`, `epic`, `decision`, or `spike`. Default to `task`.
   - **Priority:** `0` (highest) to `4`. Default to `2`; use `0` or `1` only when the user signals urgency or the work blocks other work.
   - **Description:** what and why in a few sentences, plus useful context from the conversation such as `path/to/file.ext:line` references, error text, or links. Do not invent requirements the user did not state; a one-line description is fine when there is no extra context.
   - **Acceptance criteria:** pass `--acceptance` when the finished state is clear.
   - **Parent:** pass `--parent <epic-id>` when it belongs under an epic.
   - **Dependencies:** when it waits on or blocks an existing issue, pass `--deps` (a bare `id` means this issue depends on it, `blocks:id` reverses it).
4. Create it in one call, for example `bd create "Hook up beads with Context7" -t task -p 2 -d "..."`.
5. Reply with each new ID and title on one line, followed by its type and priority. Do not start working on it unless the user asks.

## Update

Find the issue with `bd show <id>` first, then apply only the change asked for:

- **Fields:** `bd update <id>` with `--title`, `-d`, `-p`, `-t`, `--acceptance`, `--design`, `-a`, or `--parent`.
- **Notes:** `bd update <id> --append-notes "<text>"`, or `bd comment <id> "<text>"` for a discussion comment.
- **Labels:** `bd update <id> --add-label <label>` or `--remove-label <label>`.
- **Dependencies:** `bd dep add <issue> <depends-on>` and `bd dep remove <issue> <depends-on>`. "A waits on B" and "B blocks A" both mean `bd dep add A B`.
- **Defer:** `bd defer <id> --until "<when>"` to snooze, `bd defer <id>` to put it on ice, and `bd undefer <id>` to bring it back.
- **Claim or release:** `bd update <id> --claim` and `bd unclaim <id>`.

Reply with the issue ID, title, and what changed.

## Close

- **Done or dropped:** `bd close <id> [<id>...] --reason "<why>"`.
- **Duplicate:** `bd duplicate <id> --of <canonical-id>`.
- **Replaced by newer work:** `bd supersede <id> --with <new-id>`.
- **Reopen:** `bd reopen <id>`.

If closing leaves an epic with no open children, close the epic too. Reply with what was closed and anything that became ready (`bd close` takes `--suggest-next`).

## Delete

Deleting is permanent and rewrites references in connected issues to `[deleted:<id>]`. When the user might only mean they are done with an issue, offer [Close](#close) instead, which keeps the history.

1. Preview with `bd delete <id> [<id>...] --dry-run`.
2. If the user named exactly these issues and the preview touches no other issue, delete with `bd delete <id> [<id>...] --force`. Otherwise show the preview and ask before deleting.
3. Pass `--cascade` only when the user explicitly wants every dependent issue deleted too.

## Plan

Turn an approved plan into an epic whose child issues workers can pick up one at a time.

### Find the Plan

1. Use a path given in `$ARGUMENTS`.
2. Otherwise use the plan file this session's plan mode wrote.
3. Otherwise take the newest `.md` file in `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans/` and confirm it with the user before filing.

Read the whole plan.

### File the Epic

Run `bd search "<plan title>"` first. If an epic for this plan already exists, show it and ask whether to update it instead of filing a second one.

Create the epic with the plan attached both ways: `--spec-id` points at the original file, and `--design-file` copies the plan into the epic so it survives if the file is cleaned up.

```sh
bd create "<plan title>" -t epic -p <priority> \
  -d "<the goal in one or two sentences>" \
  --spec-id "<absolute plan path>" --design-file "<absolute plan path>" --silent
```

### File the Child Issues

Create one child per independently verifiable step of the plan, in plan order. Each should take more than a couple of minutes and fit in one agent session; split steps that do not, merge steps that are trivial.

- Pass `--parent <epic-id>` and `--spec-id "<absolute plan path>"`.
- **Title:** a short imperative phrase.
- **Description:** what and why, plus the plan heading it implements and any files the plan names as `path/to/file.ext:line`.
- **Acceptance criteria:** pass `--acceptance` with the plan's verification steps for that part.
- **Dependencies:** pass `--deps <earlier-id>` only when the step needs another step's output. Leave independent steps unlinked so they can run in parallel.

Do not add work the plan does not contain. Where the plan is ambiguous, record the open question in the child's description instead of inventing an answer.

### Check and Stop

Run `bd graph <epic-id>` and `bd show` a few children. Fix vague titles, missing acceptance criteria, and dependencies that are missing or that serialize work which could run in parallel.

Report the epic ID, the number of children, the `bd graph <epic-id> --compact` output, and which issues are ready first. Then stop: this session is the orchestrator. Tell the user the epic is ready for `/beads next <epic-id>` (the next step) or `/beads next <count>` (several independent steps at once). Implement in this session only when the user explicitly asks, one child at a time as [Work](#work) describes.

## Next

This session is the orchestrator. It chooses work and hands each issue to a worker subagent; it does not implement issues itself.

### Choose the Issues

- An issue ID: use it.
- An epic ID: take the top result of `bd ready --parent <epic-id> --exclude-type epic`.
- A label: take the top result of `bd ready --label <label> --exclude-type epic`.
- A number N: take up to N issues from `bd ready --exclude-type epic`. Every worker shares this working tree, so pick only issues that are unlikely to edit the same files, and say which ready issues you held back and why.
- Nothing: take the top result of `bd ready --exclude-type epic`.

If nothing is ready, say so, show `bd blocked`, and stop.

### Dispatch

For each chosen issue:

1. Claim it with `bd update <id> --claim` so the next dispatch skips it. If another actor already holds it, skip it.
2. Start a background subagent whose prompt is to invoke the `beads` skill with `work <id>` and to end with the report that skill's Work section describes. Start every chosen issue's subagent at once so they run in parallel.
3. If a subagent cannot be started, run `bd unclaim <id>` and tell the user.

### Report

List each dispatched issue's ID and title, then return to the user without waiting. As each worker finishes, relay its report: what changed, how it was verified, issues it filed, and what became ready. If a worker stopped with its issue still in progress, say what is left according to `bd show <id>`. Do not dispatch more work unless the user asks.

## Work

Complete exactly one issue, then stop. Usually an orchestrator started you as a subagent through [Next](#next).

### Pick Up the Issue

Use the issue ID from the request. If there is none, take the top result of `bd ready --exclude-type epic`, and if nothing is ready, say so and stop.

Run `bd show <id>`. Read its description, design notes, and acceptance criteria, the parent epic, and the close reasons of the issues it depended on. When the issue or its epic has a `spec_id`, read the relevant part of that plan file.

Claim it with `bd update <id> --claim`. The orchestrator usually claimed it already as the same user, which is fine. If another actor holds it, stop and say so.

### Implement

Implement only what the acceptance criteria require, following the user's and repository's instructions. Other workers may be running on the same working tree at the same time, so keep changes to the files this issue needs.

When you find work outside the issue's scope, such as a bug, a follow-up, or a missing test, file it instead of doing it:

```sh
bd create "<title>" -t <type> -p <priority> -d "<what and why>" \
  --deps discovered-from:<id>
```

If that new work blocks the current issue, link it with `bd dep add <id> <new-id>`, record progress with `bd update <id> --append-notes "<what is done, what is left>"`, run `bd unclaim <id>`, and stop to report it.

### Verify and Close

Run the checks that prove the acceptance criteria: tests, analyzers, a build, or a screenshot for UI work. If verification fails and the fix is out of scope, leave the issue in progress, append notes explaining what is left, and stop.

Once verified, close it:

```sh
bd close <id> --reason "<what changed and how it was verified>" --suggest-next
```

If that closed the last open child of an epic, close the epic too.

### Report

Give the issue ID and title, what changed as `path/to/file.ext:line` references, how it was verified, any issues filed along the way, and what became ready. Then stop; do not start another issue. As a subagent, this report is your final message to the orchestrator.
