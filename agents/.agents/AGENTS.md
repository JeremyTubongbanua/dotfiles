# AGENTS

## Non-Negotiables

- **Git is mine** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to branch `trunk` or push to upstream on my behalf.
- **No PRs or tickets.** Never create or modify pull requests or tickets unless I explicitly ask.
- **No documentation.** Never create or edit README files, guides, changelogs, API documentation, docstrings, or documentation comments unless I explicitly ask.
- **No em dashes** - in comments, code, documentation, or responses.

## Nice to haves

During a session, it would be nice if the agent did these things:

- Before starting a task, take a couple of extra seconds to think about it, do web searches to expand your knowledge on the topic and get a true deep understanding of it.
- When you finish writing code, do a quick smoke test (analyze, lint, scan, and do a basic run to ensure it builds)

## How to respond

- **Lead with the answer.** Start yes-or-no answers with "Yes" or "No".
- **Be self-contained.** Restate any prior context required to understand the response.
- **Cite code precisely.** Use `path/to/file.ext:line` when referring to repository code.
- **Summarize substantial responses.** End substantial, multi-part responses with a one-to-three-sentence "Summary" section. Omit it for short responses.

## Modes

- **Co-developer mode:** Active only when I explicitly request it. You plan and I execute. Explain for a junior engineer, provide exactly one actionable step per response, and wait for my result. It remains active until I end it.

## Shell Command Execution

- **Agent-executed commands:** Run one command per shell call. Do not combine commands with `;` or `&&`. Pipelines are allowed.
- **Concurrent processes:** When a workflow requires multiple processes, run them in tmux, provide commands to stop every session, and keep test environments ephemeral, including `docker run --rm`.
- **Handoff commands:** When asking me to experience or test changes, provide one fresh, copy-pasteable workflow that assumes no prior build state. Start with teardown when applicable. Chain dependent steps with `&&`; use `;` only when later steps should run after a failure. Break long commands across lines with `\`. Use absolute paths for file or directory arguments, and normally begin with `cd` to the absolute repository path.

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
