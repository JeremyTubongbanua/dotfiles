# AGENTS

## Non-Negotiables

- **Commits are mine.** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to trunk or production.
- **No PRs or tickets.** Never create or modify pull requests or tickets unless I explicitly ask.
- **Inspect before destructive changes.** Inspect existing files and user changes before deleting, replacing, regenerating, or overwriting anything.
- **No documentation.** Never create or edit README files, guides, changelogs, API documentation, docstrings, or documentation comments unless I explicitly ask.
- Never use em dashes in code, comments, documentation, or responses.

## How to respond

- **Lead with the answer.** Start yes-or-no answers with "Yes" or "No".
- **Present clearly.** Use lists or tables when prose gets wordy. Create self-contained HTML artifacts only when requested or when visual presentation materially improves the answer.
- **Be self-contained.** Restate any prior context required to understand the response.
- **Cite code precisely.** Use `path/to/file.ext:line` when referring to repository code.
- **Summarize substantial responses.** End substantial, multi-part responses with a one-to-three-sentence "Summary" section. Omit it for short responses.

## Modes

- **Co-developer mode:** Active only when I explicitly request it. You plan and I execute. Explain for a junior engineer, provide exactly one actionable step per response, and wait for my result. It remains active until I end it.
- **Auto mode (default):** Otherwise, complete the work without hand-holding or pauses between steps.

## Shell Command Execution

- **Agent-executed commands:** Run one command per shell call. Do not combine commands with `;` or `&&`. Pipelines are allowed.
- **Concurrent processes:** When a workflow requires multiple processes, run them in tmux, provide commands to stop every session, and keep test environments ephemeral, including `docker run --rm`.
- **Handoff commands:** Make commands copy-pasteable. Chain dependent steps with `&&`; use `;` only when failure should not stop later commands. Break long commands across lines with `\`.
- **Handoff paths:** Use absolute paths in every `cd` command.
- **Fresh and Quick:** Provide both for workflow handoffs. Fresh includes complete teardown and setup; Quick assumes clean state and runs only what is required.

## Writing Code Preferences

### Dart

Prefer explicit types, including destructured records:

```dart
final (int x, double y) = getValues();
```

### TypeScript

Prefer function expressions over declarations, explicit type annotations even when inferred, exports at the bottom of the file, and semicolons after expressions, variables, and return statements.

```tsx
const Button = (): React.JSX.Element => {
    return <div>abc</div>;
};

export default Button;
```
