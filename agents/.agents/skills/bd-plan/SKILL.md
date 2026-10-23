---
name: bd-plan
description: File an approved Claude plan-mode plan into beads as an epic with dependent child issues that link back to the plan file. Use right after a plan is approved in a repository that uses beads, or when the user runs /bd-plan.
argument-hint: [path to plan file]
---

# File a Plan into Beads

Turn an approved plan into an epic whose child issues an agent can work through one at a time with `/bd-next`.

## Find the Plan

1. Use the path in `$ARGUMENTS` when given.
2. Otherwise use the plan file this session's plan mode wrote.
3. Otherwise take the newest `.md` file in `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans/` and confirm it with the user before filing.

Read the whole plan. If `bd` reports no beads project here, ask before initializing, and initialize only with `bd init --stealth --skip-agents --role maintainer`. If `bd` fails opening a routed store such as `~/.beads-planning`, fix the role with `git config beads.role maintainer`.

## File the Epic

Run `bd search "<plan title>"` first. If an epic for this plan already exists, show it and ask whether to update it instead of filing a second one.

Create the epic with the plan attached both ways: `--spec-id` points at the original file, and `--design-file` copies the plan into the epic so it survives if the file is cleaned up.

```sh
bd create "<plan title>" -t epic -p <priority> \
  -d "<the goal in one or two sentences>" \
  --spec-id "<absolute plan path>" --design-file "<absolute plan path>" --silent
```

## File the Child Issues

Create one child per independently verifiable step of the plan, in plan order. Each should take more than a couple of minutes and fit in one agent session; split steps that do not, merge steps that are trivial.

- Pass `--parent <epic-id>` and `--spec-id "<absolute plan path>"`.
- **Title:** a short imperative phrase.
- **Description:** what and why, plus the plan heading it implements and any files the plan names as `path/to/file.ext:line`.
- **Acceptance criteria:** pass `--acceptance` with the plan's verification steps for that part.
- **Dependencies:** pass `--deps <earlier-id>` only when the step needs another step's output. Leave independent steps unlinked so they can run in parallel.

Do not add work the plan does not contain. Where the plan is ambiguous, record the open question in the child's description instead of inventing an answer.

## Check Before Reporting

Run `bd graph <epic-id>` and `bd show` a few children. Fix vague titles, missing acceptance criteria, and dependencies that are missing or that serialize work which could run in parallel.

Report the epic ID, the number of children, the `bd graph <epic-id> --compact` output, and which issues are ready first.

Then stop. This session is the orchestrator: tell the user the epic is ready to dispatch with `/bd-next <epic-id>` for the next step or `/bd-next <count>` for several independent steps at once, each worked by its own subagent. Implement in this session only when the user explicitly asks, one child at a time as `/bd-work` describes.
