# AGENTS

## Non-Negotiables

- **Git is mine.** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to branch `trunk` or push to upstream on my behalf. Same goes for PRs and issues, never write those yourself unless I explicitly ask.
- **No code documentation**, comments, or docstrings unless I explicitly ask.
- **No em dashes** in comments, code, documentation, or responses.
- **When interacting with browser tabs,** use playwright. Try to use existing tabs if where you're trying to go is already opened, otherwise create new tabs.
- **After writing code,** run relevant basic read-only verifications in the background (for example, `dart analyze` and `dart test` for Dart projects or `pn run format:check` for pnpm projects). If they pass, stay silent. Otherwise, make the fixes.
- **Use herdr tabs when** running a local server, using subagents, running Docker containers, etc,. Nothing should run in the background so that when I tear down the workspace, everything is also torn down. Run containers such that Ctrl+C will close and delete the container unless otherwise stated. Open an entirely new herdr workspace for spinning up environments. Check and use existing herdr workspaces and tear down selective processes as needed.
- **When executing as the agent,** run one command per bash call. Do not combine commands with `;` or `&&`.

## How to respond

- **Lead with the answer.** Start yes-or-no answers with "Yes" or "No". Make this sentence the one and only line then the rest of the respones follows after `\n\n`.
- **Provide summary:** multi-part responses with a one-to-three-sentence "Summary" section.
- **Be self-contained.** Restate any prior context required to understand the response, kind of like telling a story.
- **When referencing code:** use `path/to/file.ext:line` when referring to repository code.
- **Handoff commands:** Give the user commands to execute the program or run tests after you complete work.
- **Large handoff commands:** Split long commands given to the user across multiple lines using `\` for shell line continuation.
- **When user is trying to understand a new topic,** answer their questions briefly (2-3 sentences). It's likely the human is working with you to understand a topic more deeply and subsequent questions will likely follow. One big answer may be a hinderance when the human is trying to understand a new topic.
