---
name: noports-e2e-all-v2-editing
description: Use for repeated work in jt-e2e-all-v2 under tests/e2e_all_v2, especially policy/core test refactors, Docker/APKAM utility moves, CLI flag edits, and output-format changes.
argument-hint: "[path-or-subarea]"
disable-model-invocation: true
user-invocable: false
allowed-tools:
  - functions.exec_command
  - functions.apply_patch
---

# noports-e2e-all-v2-editing

## When to use

Use this skill when working in `/Users/jeremytubongbanua/GitHub/noports/jt-e2e-all-v2`, especially:

- `tests/e2e_all_v2/lib/core_tests/**`
- `tests/e2e_all_v2/lib/policy_tests/**`
- `tests/e2e_all_v2/lib/docker*.dart`
- `tests/e2e_all_v2/lib/apkam_setup.dart`
- `tests/e2e_all_v2/bin/*.dart`
- `.github/workflows/e2e_all.yaml`

Non-goals:

- broad repo-wide refactors outside `e2e_all_v2`
- styling-only edits unless the user explicitly asks for them
- full-package analyzer sweeps when the task only touches a few files

## Inputs / context to gather

1. Confirm the exact subarea with `rg` before editing.
2. Read the concrete sibling file the user references before abstracting:
   - for sshnp file simplifications, inspect a known-good peer such as `v4_dart_inline.dart`
   - for policy flow, inspect `core_tests.dart` and the shared `lib/docker_utils.dart` helpers
3. Check whether the user is asking for:
   - file-local logic instead of helpers
   - shared helper extraction
   - CLI rename with backward-compatible alias
   - policy/core workflow split in GitHub Actions

## Procedure

1. Search first with repo terms, not guesses.
   - `rg -n "npp-at-server-versions|npp-atserver-versions|nppAtServerVersions" tests/e2e_all_v2`
   - `rg -n "formatDuration|Overall time|Setup time|completed in" tests/e2e_all_v2`
   - `rg -n "runDockerInstance|ensureDockerVersionsBuiltParallel|PolicyServerType" tests/e2e_all_v2`
2. Preserve the repo's separation rules.
   - Keep shared image/start helpers in `tests/e2e_all_v2/lib/docker_utils.dart`.
   - Keep suite-specific orchestration in `core_tests/` or `policy_tests/`.
   - For sshnp tests, prefer file-local `_generateVersionPermutations` and inline `getDeviceNameNoFlags(... )_f` when the user is asking for simpler colocated code.
3. For policy work, mirror the proven flow.
   - Use `bin/policy_tests.dart` as the entrypoint, not `bin/core_tests.dart`.
   - Reuse `runDockerInstance(...)`.
   - Treat readiness as a log-line check, not only a process-state check.
   - Keep NPP and NPP-atServer logic separate when the user asks for separate permutations/files.
4. For CLI renames, update every user-facing touchpoint.
   - parser primary flag
   - parser alias for backward compatibility unless user wants a breaking change
   - printed parameter labels
   - any example command or workflow flag
5. Verify with the smallest reliable command.
   - touched Dart files: `dart analyze <file1> <file2> ...`
   - broader `tests/e2e_all_v2` tree only when the change is spread across many sibling files
   - workflow edits: parse the YAML or run the narrow validation command available in-repo

## Efficiency plan

- Start with `rg` to identify the true source of truth before opening files.
- Prefer targeted `dart analyze` on touched files; full-package analysis can surface unrelated issues.
- Reuse existing helpers instead of re-reading the whole suite:
  - `lib/docker_utils.dart`
  - `lib/apkam_setup.dart`
  - `lib/print_test_utils.dart`
- Stop once the touched files analyze cleanly and any requested log/output string matches the user's wording exactly.

## Pitfalls and fixes

- Symptom: policy flags are rejected.
  - Likely cause: using `bin/core_tests.dart` instead of `bin/policy_tests.dart`.
  - Fix: run or wire `bin/policy_tests.dart`.
- Symptom: `Bad state: Stream has already been listened to.`
  - Likely cause: second listener added to a `docker run` process already captured by shared helpers.
  - Fix: rely on `runDockerInstance(...)` capture; remove duplicate listeners.
- Symptom: policy container looks missing or fails readiness too early.
  - Likely cause: readiness check is process-state based and races startup.
  - Fix: poll logs first and print the exact matched readiness line.
- Symptom: analyzer errors after moving test bodies.
  - Likely cause: missing direct imports that were previously inherited through shared helpers.
  - Fix: add the print/helper imports explicitly in each file.
- Symptom: duplicate Docker image builds for the same version.
  - Likely cause: dedupe handled locally instead of through shared helper.
  - Fix: route image setup through `ensureDockerVersionsBuiltParallel(...)`.

## Verification checklist

- Requested naming/output strings match the user's wording exactly.
- Shared vs suite-specific file placement matches the user's latest correction.
- Policy changes keep NPP and NPP-atServer paths distinct where requested.
- No new styling-only churn was introduced.
- `dart analyze` passed on the touched files or target subtree.
