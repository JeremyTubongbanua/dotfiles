# CLAUDE

## Verification

- After every implementation, run a smoke test: compile/build the project and exercise the broader system (not just the new feature) to catch regressions and compilation errors. Report the result before claiming done.

## Handoff commands

- After completing a feature, give the user two copy-pasteable shell commands to run it:
  1. **Fresh:** full teardown then run (e.g. stop containers, remove volumes/dirs, then start).
  2. **Quick:** run only, assuming current state is clean.
  Use fenced code blocks, one command per block, no placeholders the user has to fill in.

## Git

- I like my default branch as `trunk` and remote named `upstream`.
- **Never run `git add`, `git commit`, or `git push`** unless I explicitly ask. I handle commits myself.
- **Clone with SSH URLs** (`git@github.com:...`), never HTTPS.
- **Remote naming:** I name the primary remote `upstream`, not `origin`. When cloning or adding remotes, use `upstream`.
- **Repo layout:** repos live in `~/GitHub/<org>/<name>/`, organised by org: `atsign/` (at_client_sdk, at_server, noports, …), `personal/` (dotfiles, campuseats, …), `jeremylabs/`, `align/`. Most are standard single-root repos (`~/GitHub/<org>/<name>/.git`). A few are worktree collections — in those, `~/GitHub/<org>/<name>/trunk/` holds the upstream trunk checkout and sibling directories hold feature worktrees.
- **Worktree workflow** (for worktree-collection repos):
  ```sh
  cd ~/GitHub/<org>/<name>/trunk
  git fetch upstream
  git reset --hard upstream/trunk
  git worktree add -b jt-<feature> ../jt-<feature>
- Branch naming: jt-<short-description> (e.g. jt-fix-barrett, jt-add-mlkem-1024).

## Dart

In dart types, I like to be explicit.

```dart
// Works, but don't really like...
(x, y) = getValues();

// I like
final (int x, double y) = getValues();
```
