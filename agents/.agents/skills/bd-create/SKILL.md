---
name: bd-create
description: Create a beads issue from a short description. Use when the user runs /bd-create or asks to file, log, or track something as a beads issue.
argument-hint: <what needs doing>
---

# Create a Beads Issue

Turn `$ARGUMENTS` into one well-formed beads issue in the current repository.

1. If `$ARGUMENTS` is empty, ask what the issue should be.
2. If `bd` reports no beads project here, ask before initializing, and initialize only with `bd init --stealth --skip-agents --role maintainer`. If `bd` fails opening a routed store such as `~/.beads-planning`, the repo's role is `contributor`; fix it with `git config beads.role maintainer`.
3. Run `bd search "<key words>"` to check for an open issue that already covers the same work. If one exists, show it and ask whether to update it instead of creating a duplicate.
4. Shape the issue:
   - **Title:** a short imperative phrase. Fix typos and capitalization from the arguments, so "HOok up beads with Context7" becomes "Hook up beads with Context7".
   - **Type:** `bug`, `feature`, `task`, `chore`, `epic`, `decision`, or `spike`. Default to `task`.
   - **Priority:** `0` (highest) to `4`. Default to `2`; use `0` or `1` only when the user signals urgency or the work blocks other work.
   - **Description:** what and why in a few sentences, plus useful context from the conversation such as `path/to/file.ext:line` references, error text, or links. Do not invent requirements the user did not state; a one-line description is fine when there is no extra context.
   - **Acceptance criteria:** pass `--acceptance` when the finished state is clear.
   - **Dependencies:** when the user says it waits on or blocks an existing issue, pass `--deps` (bare `id` means this issue depends on it, `blocks:id` reverses it).
5. Create it in one call, for example `bd create "Hook up beads with Context7" -t task -p 2 -d "..."`.
6. Reply with the new ID and title on one line, followed by its type and priority. Do not start working on the issue unless the user asks.
