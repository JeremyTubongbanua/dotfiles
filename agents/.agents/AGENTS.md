# AGENTS

## Non-Negotiables

- **Commits are mine.** Never `git add`, `git commit`, or `git push` unless I explicitly ask. Never push to trunk or production.
- **No PRs/tickets** unless I explicitly ask.
- **Look before you destroy.** Check for existing assets before any `rm -rf xyz; mkdir -p xyz`.
- **No code documentation.** I write my own docs.
- **No em-dashes anywhere.** - not in code, responses, documentation, or comments.

## How to respond

- **Lead with the answer.** Yes/no questions start with "Yes" or "No".
- **Present clearly.** Lists and tables when prose gets wordy. Self-contained HTML artifacts for visual info.
- **Don't assume I read everything.** Don't expect me to remember something from 3 responses ago.
- **Summary**: 1–3 sentence "Summary" section per response, skip if the response is already short.

### Manual mode (default)

Peer-programming: you plan, I execute. I'm a junior engineer, explain slowly with examples. One step per message, then stop and wait for my response (e.g. "I ran it"). Never batch major steps; break into numbered sub-steps if needed, but send only one step.

### Auto mode

Do everything. No hand-holding. No waiting between steps.

## Shell Command Execution

- **One command per Bash call.** When Claude is executing commands, don't bundle with `;` or lls. `|` is fine when the pipe *is* the command. Chaining defeats the permission allowlist which matches the whole command string.
- **Smoke test after every change.** Build and exercise the broader system, not just the new feature. Report results before claiming done.
- **Handoff commands.** Copy-pasteable shell commands chained with `&&` (`;` only where failure shouldn't stop the chain). Include setup steps like `cd /abs/path && dart pub get`.
  - **Absolute directories** in any `cd` commands you give me.
  - **Fresh:** full teardown, then run.
  - **Quick:** run only, assuming clean state.

## Writing code preferences

### Dart

```
Prefer explicit types.
// Don't like
(x, y) = getValues();

// Prefer
final (int x, double y) = getValues();
```

### TypeScript

Prefer functional expressions over declarations (no hoisting), explicit type annotations even when inferred, exports at bottom of file, semicolons after expressions/variables/returns.

```
// Don't like
export default function Button() {
    return <div></div>
}

// Prefer
const button: ReactComponent = () => {
    return (<div>abc</div>);
};

export default button;
```
