# AGENTS

## Non-Negotiables

- **Git is mine.** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to branch `trunk` or push to upstream on my behalf. Same goes for PRs and issues, never write those yourself unless I explicitly ask.
- **No code documentation**, comments, or docstrings unless I explicitly ask.
- **No em dashes** in comments, code, documentation, or responses.
- **When interacting with browser tabs,**
    - use claude in chrome. if claude in chrome is unavailable, use playwright.
    - in conjunction, use Chrome Devtools to help you debug
    - reuse an existing tab instead of opening a new one whenever you can. First list the open tabs, then use a tab already on the page or site you need, or else navigate a tab an agent opened earlier, such as one in Claude's tab group. Open a new tab only when neither exists, and never navigate away from one of my own tabs on an unrelated page. This rule is my standing request to reuse existing tabs, so it overrides any default that says to create a new tab unless asked.
    - never close any tab, window, or browser, including tabs you opened yourself, by any means: no close tool, no `window.close()`, and no Cmd+W or Ctrl+W. Leave every tab open when you are done. I always want the tabs kept, which overrides the Claude in Chrome skill's instruction to close the tabs it created before finishing.
- **After writing code,** run the relevant read-only verifications yourself in the background instead of handing commands to me: tests, analyzers, linters, type checks, check-only format checks, and dry runs (for example, `dart analyze` and `dart test` for Dart projects or `pn run format:check` for pnpm projects). If they pass, stay silent. Otherwise, make the fixes. Never run formatters or anything else that rewrites files (for example, `dart format`, `dart fix --apply`, or `pn run format`) unless I say it's okay.
- **Use herdr tabs when** running a local server, running Docker containers, etc,. Nothing should run in the background so that when I tear down the workspace, everything is also torn down. Run containers such that Ctrl+C will close and delete the container unless otherwise stated. Open an entirely new herdr workspace for spinning up environments. Check and use existing herdr workspaces and tear down selective processes as needed. Subagents are the exception: use Claude's built-in subagents, not herdr tabs.
- **When asked to open a new herdr workspace, worktree, or branch for a task,** hand the task to a claude-work or pi agent in that new workspace with the `herdr-delegate` skill, then stop. Never do the task in the current session.
- **Keep scratch files out of repos.** Put throwaway scripts, test fixtures, logs, local databases, and other local testing state under `/tmp` (for example `/tmp/<repo-name>/`), never in the working tree, so `git status` only shows real code changes.
- **Update the changelog when making changes** in a repo that has one, under the right version. First find the version in production, meaning the latest published package, release, or deployment (for example `gh release list`, `npm view <pkg> version`, or pub.dev), and compare it with the version on trunk. If trunk's version is newer than production and not yet released, add the changes under that version. If trunk's version matches production, bump the version everywhere the repo declares it, following the project's versioning scheme, and add the changes under a new section for the new version.
- **When executing as the agent,** run one command per bash call. Do not combine commands with `;` or `&&`.
- **When initializing beads,** run `bd init --stealth --skip-agents --role maintainer`. Never let beads add `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/`, or tracked `.beads/` files to a repo, and never run `bd setup <tool>` inside a repo.
- **After a plan is approved in plan mode** in a repo that uses beads, file it with the `use-beads` skill and stop. The planning session orchestrates; the user dispatches each step to a worker subagent with `/use-beads next`.
- **Be self-improving**, when the user doesn't like how an agent skill, mcp server, script, or tool works, go and change it yourself. Only things in ~/GitHub/personal/dotfiles should be editable in that sense.

## How to respond

- **Lead with the answer.** When I ask a question, the first part of the response is a one-sentence answer on its own line, starting with "Yes" or "No" whenever the question allows it. The rest of the response follows after `\n\n`.
- **End with a summary.** Every response ends with a one-to-three-sentence "Summary" section. Nothing comes after it.
- **Tell me how to respond.** The very last sentence of the summary, and so of the whole response, tells me what to reply, for example "Should I go ahead with changing feature A?"
- **When referencing code:** use `path/to/file.ext:line` when referring to repository code.
- **When user is trying to understand a new topic,** answer their questions briefly (2-3 sentences). It's likely the human is working with you to understand a topic more deeply and subsequent questions will likely follow. One big answer may be a hinderance when the human is trying to understand a new topic.
