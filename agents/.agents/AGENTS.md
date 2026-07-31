# AGENTS

## Non-Negotiables

- **Commits are mine.** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. **NEVER PUSH TO TRUNK.**
- **Read a file before editing it.**
- **Look before you destroy.** Check for existing assets before any `rm -rf xyz; mkdir -p xyz` — don't wipe out work.

## Working With Me

I'm autistic. These aren't style preferences — they're how I work best. Follow them exactly.

- **Pace.** One step per message, then stop and wait. Never batch major steps; break one step into numbered sub-steps if needed, but send only that step. Wait for my response (e.g. "I ran it") before the next.
- **Lead with the answer.** For yes/no questions, start with "Yes" or "No", then explain. Don't bury the answer under caveats.
- **Be concise, not vague.** Prefer conciseness but never sacrifice clarity; 1–2 short paragraphs max. Bullets and numbered lists over prose. I'll ask follow-ups.
- **Be concrete and direct.** Exact commands, exact file contents. No hedging ("you should probably", "maybe try"). Show what you reference — code sample, file path, or example.
- **Think before messaging.** Settle on one position before sending. Never reason mid-message, contradict yourself, or reverse a claim within the same reply. If a yes/no needs verification first, verify (read the file, check), then answer once — don't answer and then walk it back.
- **Stage code so each commit is atomic.** Add code in meaningful stages; don't reference something that doesn't exist yet. E.g. create `functions/` and its files before adding `include: ["functions/**/*"]` to `tsconfig.json`. Each stage must stand on its own.
- **No surprise changes.** Departing from the plan, recipe, or convention? Stop and flag it first — name the change, give the tradeoff, wait for my call. Don't silently swap `.env` for `.dev.vars`.
- **Present clearly.** Use lists and matrix tables when prose can't stay concise. For high-fidelity visual information, use a self-contained HTML artifact.
- **Reuse existing concepts.** Avoid new terminology when a concept already exists; check the codebase before proposing new terms.
- **Speak up.** If I've given you too much at once, or a plan seems wrong, say so directly.
- **Learning Mode.** I do AI-assisted coding, not vibe coding. Sometimes I want you to develop the plan and I carry it out by hand (create files, write code, run commands) — you're my peer-programmer. I'm a junior engineer: explain slowly, with examples and code samples, and keep simple answers to 3–5 sentences.

## Execution

- **One command per Bash call.** This applies only to commands *you* execute — not to handoff commands, which I run myself and want chained. Never bundle unrelated steps with `;` or `&&`; issue them as separate tool calls (in parallel when they don't depend on each other). `|` is fine when the pipe *is* the command (`grep foo src/ | head -20`), not when it's stapling steps together. Chaining defeats the permission allowlist, which matches the whole command string — `ls *` won't match `ls -la . ; cat foo`.
- **Smoke test after every change.** Compile/build the project and exercise the broader system (not just the new feature) to catch regressions and compilation errors. Report the result before claiming done.
- **Handoff commands.** After completing a feature, give me copy-pasteable shell commands to run it — no placeholders I have to fill in:
  - **Fresh:** full teardown, then run (e.g. stop containers, remove volumes/dirs, then start).
  - **Quick:** run only, assuming current state is clean.
  - **Chain every step into one fenced block with `&&`** (use `;` only where a failure should not stop the chain). Do not hand me a step-by-step list to run one at a time.
  - Include setup steps like `cd packages/dart_package && dart pub get` so packages are installed.

## Git

- Default branch is `trunk`; the primary remote is named `upstream`, not `origin`.
- Clone with SSH URLs (`git@github.com:...`), never HTTPS. Add remotes as `upstream`.
- **Repo layout:** repos live in `~/GitHub/<org>/<name>/`, organised by org — `atsign/` (at_client_sdk, at_server, noports, …), `personal/` (dotfiles, campuseats, …), `jeremylabs/`, `align/`. Most are standard single-root repos (`~/GitHub/<org>/<name>/.git`). A few are worktree collections: `~/GitHub/<org>/<name>/trunk/` holds the upstream trunk checkout and sibling directories hold feature worktrees.
- **Worktree workflow** (for worktree-collection repos):
  ```sh
  cd ~/GitHub/<org>/<name>/trunk && git fetch upstream && git reset --hard upstream/trunk && git worktree add -b jt/<feature> ../jt/<feature>
  ```

## Dart

Prefer explicit types.
```dart
// Works, but don't really like...
(x, y) = getValues();

// I like
final (int x, double y) = getValues();
```

## TypeScript

Prefer:
- functional expressions over declarations (I don't like hoisting)
- explicit type annotations on variables, even when they're inferred
- exports at the bottom of the file
- semicolons after functional expressions, variables, and return statements

```ts
// Don't like
export default function Button() {
    return <div></div>
}

// Instead:
const button: ReactComponent = () => {
    return (<div>abc</div>);
};

export default button;
```

## Symlinks

Before editing a file, quickly check if it's a symlink. It may even be a symlink pointing to a symlink. Be sure to propose edits to the source of truth.
