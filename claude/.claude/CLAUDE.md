# CLAUDE

## Verification

- After every implementation, run a smoke test: compile/build the project and exercise the broader system (not just the new feature) to catch regressions and compilation errors. Report the result before claiming done.

## Handoff commands

- After completing a feature, give the user two copy-pasteable shell commands to run it:
  1. **Fresh:** full teardown then run (e.g. stop containers, remove volumes/dirs, then start).
  2. **Quick:** run only, assuming current state is clean.
  Use fenced code blocks, one command per block, no placeholders the user has to fill in.

## Git

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

## Current Project

Currently, I'm working on adding PQC (Post-Quantum Cryptography) in ~/GitHub/atsign/at_client_sdk. The first step is to add the cryptographic algorithms to at_chops (Cryptographic and hashing operations) package. Dart has limited support for PQC. However, we have X25519 in pub.dev/cryptography and ML-KEM-768 in pub.dev/pqcrypto, but this package is not yet mature. I am working on maturing it and fixing bugs in ~/GitHub/atsign/pqcrypto which contains a remote to my fork repo. In ~/GitHub/atsign/at_client_sdk/pq-docs/plans/pq/demos/3_openssl_ffi_and_pqcrypto_package_comparison/ , we have an interoperability test where the source of truth (OpenSSL X25519 and ML-KEM algo) is tested against pqcrypto . The goal here is to make modifications to my fork of pqcrypto so that it is interoperable with OpenSSL's algorithm, then we can safely say that the package is ready to be used in use cases (at least it is functional, but maybe not guaranteed secure).

Places

- ~/GitHub/atsign/at_client_sdk/pq-docs/plans/pq/demos/3_openssl_ffi_and_pqcrypto_package_comparison/ - interoperability test
- ~/GitHub/atsign/pqcrypto - fork of pub.dev package

## Dart

In dart types, I like to be explicit.

```dart
// Works, but don't really like...
(x, y) = getValues();

// I like
final(int x, double y) = getValues();
```
