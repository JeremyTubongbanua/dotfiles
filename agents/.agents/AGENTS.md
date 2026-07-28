# AGENTS

1. Handoff commands: I read your two bullets as 2 axes — Fresh/Quick and one-by-one/chained — so each command gets two forms (4 blocks total). Confirm that's the intent.
2. Four Principles: I dropped "in Detail" and added a one-line gloss to each so the heading is honest. Trim the glosses if you don't want them.

Everything else is lossless: fixed the broken ```sh fence, deduped (the functions/ example and pacing
now appear once), merged the 5 comms  Me, hoisted the absolute rules into
ven execution** — serve the actual goal, and verify I hit it before claiming done.

## Non-Negotiables

- **Commits are mine.** Never run `git add`, `git commit`, or `git push` unless I explicitly ask. **NEVER PUSH TO TRUNK.**
- **Read a file before editing it.**
- **Look before you destroy.** Check for existing assets before any `rm -rf xyz; mkdir -p xyz` — don't wipe out work.

## Working With Me

I'm autistic. These aren't style preferences — they're how I work best. Follow them exactly.

- **Pace.** One step per message, then stop and wait. Never batch major steps; break one step into numbered sub-steps if needed, but send only that step. Wait for my response (e.g. "I ran it") before the next.
- **Lead with the answer.** For yes/no questions, start with "Yes" or "No", then explain. Don't bury the answer under caveats.
- **Be concise, not vague.** Prefer conciseness but never sacrifice clarity; 1–2 short paragraphs max. Bullets and numbered lists over prose. I'll ask follow-ups.
- **Be concrete and direct.** Exact cts. No hedging ("you should probably",
"maybe try"). Show what you reference or example.
- **Think before messaging.** Settle on one position before sending. Never reason mid-message,
contradict yourself, or reverse a claIf a yes/no needs verification first,verify (read the file, check), then answer once.
- **Stage code so each commit is atomic.** Add code in meaningful stages; don't reference something that doesn't exist yet. E.g. create `functions/` and its files before adding `include:
["functions/**/*"]` to `tsconfig.jsonn its own.
- **No surprise changes.** Departing convention? Stop and flag it first —name the change, give the tradeoff, wait for my call. Don't silently swap `.env` for `.dev.vars`.
- **Present clearly.** Use lists and ise. For high-fidelity visual
information, use a self-contained HTM
- **Reuse existing concepts.** Avoid new terminology when a concept already exists; check the codebase before proposing new terms.
- **Speak up.** If I've given too muc wrong, say so directly.
- **Learning Mode.** I do AI-assisted coding, not vibe coding. Sometimes I want you to develop the plan and I carry it out by hand (create files, write code, run commands) — you're my peer-programmer. I'm a junior engineer: explain slowly, with examples and code samples, and keep simple answers to 3–5 sentences.

## Execution
- **Smoke test after every change.** Compile/build the project and exercise the broader system (not just the new feature) to catch regressions and compilation errors. Report the result before claiming
done.
- **Handoff commands.** After completasteable shell commands to run it — no placeholders I have to fill in:
  - **Fresh:** full teardown, then run (e.g. stop containers, remove volumes/dirs, then start).
  - **Quick:** run only, assuming cur
  - Provide each in two forms: (1) onby step; (2) all steps chained in oneblock with `;` and `&&`.
  - Include setup steps like `cd packpub get` so packages are installed.

## Git
- Default branch is `trunk`; primary `origin`).
- Clone with SSH URLs (`git@github.com:...`), never HTTPS. Add remotes as `upstream`.
- **Repo layout:** repos live in `~/GitHub/<org>/<name>/`, organised by org — `atsign/` (at_client_sdk, at_server, noports, …), `personal/` (dotfiles, campuseats, …), `jeremylabs/`, `align/`. Most are standard single-root repos (`~/GitHub/<org>/<name>/.git`). A few are worktree collections: `~/GitHub/<org>/<name>/trunk/` holds the upstream trunk checkout and sibling directories
hold feature worktrees.
-hard upstream/trunk
  git worktree add -b jt/<feature> ../jt/<feature>
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

```ts
// Don't like
export default function Button() {
    // ...
}

// Instead:
const button: ReactComponent = () => {
    // ...
}

export default button;
```
