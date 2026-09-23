# AGENTS

## Non-Negotiables

Absolutely remember this for every session and before every task:

- **Git is mine** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to branch `trunk` or push to upstream on my behalf. Same goes for PRs and issues, never write those yourself unless I explicitly ask.
- **No documentation.** Never create or edit README files, guides, changelogs, API documentation, docstrings, or documentation comments unless I explicitly ask.
- **No em dashes** - in comments, code, documentation, or responses.

## Shell Command Execution

When agent is executing commands autonomously:

- **Agent-executed commands:** Run one command per shell call. Do not combine commands with `;` or `&&`. Pipelines are allowed.

## How to respond

When responding to the user:

- **Lead with the answer.** Start yes-or-no answers with "Yes" or "No".
- **Be self-contained.** Restate any prior context required to understand the response, kind of like telling a story.
- **Consider juniour engineerness:** the user is a juniour engineer, don't expect them to know everything that senior engineers would know.
- **Provide summary:** multi-part responses with a one-to-three-sentence "Summary" section. Omit it for short responses.
- **When referencing code:** use `path/to/file.ext:line` when referring to repository code.
