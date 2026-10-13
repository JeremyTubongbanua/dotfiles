# AGENTS

## Non-Negotiables

- **Git is mine** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to branch `trunk` or push to upstream on my behalf. Same goes for PRs and issues, never write those yourself unless I explicitly ask.
- **No code documentation.** No code documentation, comments, or docstrings unless I explicitly ask.
- **Update docs/agents.** Use this as your persistenet age context. After completing a task or anything, update these so that when another agent picks up work, look at these docs.
- **Read docs/agents.** If docs/agents exists, reference it before continuing. You may be picking up work from another agent from another day. There's a chance they're also stale so verify your claims by reading actual code.
- **No em dashes** - in comments, code, documentation, or responses.
- **Browser tabs:** When navigating in a browser, open a new tab instead of navigating away from a tab that is already open. Leave existing tabs intact unless I explicitly ask you to use one. Use playwright. Only use playwright for ComeAlign-related stuff; unless otherwise specified.
- **Verification after code changes:** run relevant basic read-only checks yourself (for example, `dart analyze` and `dart test` for Dart projects or `pn run format:check` for pnpm projects). If they pass, stay silent. Otherwise, make the fixes.
- **Use herdr tabs when** running a local server, using subagents, running Docker containers, etc,. Nothing should run in the background so that when I tear down the workspace, everything is torn down. Run containers such that Ctrl+C will close and delete the container unless otherwise stated. Open an entirely new workspace for spinning up environments. Open sub workspaces in herdr.
- **Agent-executed commands:** Run one command per bash call. Do not combine commands with `;` or `&&`. Pipelines are allowed.

## How to respond

- **Lead with the answer.** Start yes-or-no answers with "Yes" or "No".
- **Be self-contained.** Restate any prior context required to understand the response, kind of like telling a story.
- **Provide summary:** multi-part responses with a one-to-three-sentence "Summary" section.
- **When referencing code:** use `path/to/file.ext:line` when referring to repository code.
- **Handoff commands:** Give the user commands to execute the program or run tests after you complete work.
- **Large handoff commands:** Split long commands given to the user across multiple lines using `\` for shell line continuation.
