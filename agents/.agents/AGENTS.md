# AGENTS

## Four Principles in Detail

1. Think before coding
2. Simplicity first
3. Surgical changes
4. Goal-driven execution

## Simpler Explanations

When explaining things back to the user, be simple. Not too wordy and no more than 1-2 paragraphs. I prefer bullet points and ordered lists (1, 2, 3, ...) and examples whenever you reference something.

I also like it when you only give one step at a time. Instead of giving multiple major steps at once, just give the first major step (sometimes broken into sub minor steps), and I usually want to ask a question or give some feedback like "I ran it" once I've done it. Then you can give the next step.

I don't like to add code file-by-file. I instead like to add code that makes sense at each stage. For example, I don't want to add `include: ["functions/**/*"]` to my `tsconfig.json `when `functions/` is a non-existent file. I would instead want to first make `functions/` and whatever files in there, and THEN add that `include:` to my `tsconfig.json`. The reason for this is so I can do atomic commits.

## User Interaction

I'm autistic. These aren't style preferences — they're how I work best. Follow them exactly.

- Prefer conciseness when reporting information to the user, do not sacrifice clarity for conciseness.
- Be pragmatic and direct with communication to the user.
- Pace. One action per message, then stop and wait. Never batch major steps — number sub-steps if needed, but keep it to that one step. Next step only after I respond.
- Be concrete. Exact commands, exact file contents. No hedging ("you should probably", "maybe try"). Show what you reference — code sample, file path, or example.
- Lead with the answer. Yes/no questions: start with "Yes" or "No", then explain. Don't bury it under caveats.
- No surprise changes. Departing from the plan, recipe, or convention? Stop and flag it first — name the change, give the tradeoff, wait for my call. Don't silently swap .env for .dev.vars.
- Keep it short. Bullets and numbered lists over paragraphs; 1-2 short paragraphs max. I'll ask follow-ups.
- Add code in meaningful stages. Don't reference something that doesn't exist yet — create functions/ and its files before adding include: ["functions/**/*"] to tsconfig.json. I commit atomically, so each stage must stand on its own.
- Speak up. Too much at once, or a plan that seems wrong? Say so directly.

## Presenting Information
- Use lists and matrix tables to surface information when it is otherwise difficult to remain concise.
- If you need to convey high fidelity visual information, consider a self-contained html artifact.

## Communicating Concepts
- Avoid creating new terminology when existing concepts may already exist.
- Check the codebase before proposing new terms for the user to review.

## File System Interaction
- Read before editing files
- Always check for existing assets before running the `rm -rf xyz; mkdir -p xyz` pattern.

## Quick Test

- After every implementation, run a smoke test: compile/build the project and exercise the broader system (not just the new feature) to catch regressions and compilation errors. Report the result before claiming done.

## Handoff commands

- After completing a feature, give the user two copy-pasteable shell commands to run it:
  1. **Fresh:** full teardown then run (e.g. stop containers, remove volumes/dirs, then start).
  2. **Quick:** run only, assuming current state is clean.
  Use fenced code blocks, one command per block, no placeholders the user has to fill in.

- Give me two versions: first version is one-by-one and the second one uses `;` and `&&`
- Don't forget to include things like `cd packages/dart_package && dart pub get` in the instructions to ensure packages are installed.

## Git

- I like my default branch as `trunk` and remote named `upstream`.
- **Never run `git add`, `git commit`, or `git push`** unless I explicitly ask. I handle commits myself. And most importantly, NEVER PUSH TO TRUNK
- **Clone with SSH URLs** (`git@github.com:...`), never HTTPS.
- **Remote naming:** I name the primary remote `upstream`, not `origin`. When cloning or adding remotes, use `upstream`.
- **Repo layout:** repos live in `~/GitHub/<org>/<name>/`, organised by org: `atsign/` (at_client_sdk, at_server, noports, …), `personal/` (dotfiles, campuseats, …), `jeremylabs/`, `align/`. Most are standard single-root repos (`~/GitHub/<org>/<name>/.git`). A few are worktree collections — in those, `~/GitHub/<org>/<name>/trunk/` holds the upstream trunk checkout and sibling directories hold feature worktrees.
- **Worktree workflow** (for worktree-collection repos):
  ```sh
  cd ~/GitHub/<org>/<name>/trunk
  git fetch upstream
  git reset --hard upstream/trunk
  git worktree add -b jt/<feature> ../jt/<feature>

## Dart

In dart types, I like to be explicit.

```dart
// Works, but don't really like...
(x, y) = getValues();

// I like
final (int x, double y) = getValues();
```

## TypeScript

In TypeScript, I prefer:
- functional expressions over declarations (I don't like hoisting)
- typing my variables, even though they're detected at runtime
- exports at the bottom of the file

See example below that displays all 3 of these:

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

## Peer Programming Philosophy

I like to do AI-assisted coding (not vibe coding and there's a difference). Sometimes when I am in "Learning Mode" I want Claude to develop a plan for me, and I carry out that plan manually myself (create the files, write the code, execute the commands). In this mode, I want Claude to be my peer-programmer in this scenario.

I am still a juniour engineer so you have to explain things slowly to me. Use less sentences when I ask a simple question (3-5 sentences). Explain reasoning with exampeles and code samples.
