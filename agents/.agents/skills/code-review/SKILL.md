---
name: code-review
description: Review a pull request, the current branch, or another proposed change against trunk, including its GitHub checks and discussion when available. Use when asked to find regressions, breaking changes, code-quality problems, or edge cases before merge.
---

# Code Review

Review the proposed change as code that may enter an otherwise stable trunk. Find concrete defects and compatibility risks introduced by the change; do not treat pre-existing trunk behavior as a finding unless the change makes it newly relevant or worse.

## Establish the Review Target

Determine whether the user named a PR, supplied a diff, or wants the current branch reviewed. Prefer the repository's configured default branch as trunk; respect an explicitly named base branch. Record the exact base and head revisions used so the review does not silently rely on an ambiguous or stale comparison.

When GitHub access is available:

- For a named PR, inspect its title, description, base and head branches, commits, changed files, reviews, issue comments, inline review comments, and check results.
- For the current branch, look for an associated open PR. If one exists, use its base branch and include its metadata, discussion, and checks. If none exists, review the branch locally against trunk.
- Read existing comments as leads and context, not as established truth. Verify whether raised issues remain present in the latest head, and avoid repeating resolved or obsolete comments as new findings.
- Inspect failed, cancelled, or pending GitHub Actions checks. Open failed job logs when possible and decide whether the failure is caused by the change, exposes a real regression, or appears unrelated or infrastructural.

Do not create reviews, post comments, push commits, rerun workflows, or otherwise mutate GitHub state unless the user explicitly asks.

## Build the Complete Diff

Use a merge-base comparison equivalent to:

```sh
base=$(git merge-base HEAD <trunk-ref>)
git diff --find-renames "$base"...HEAD
```

This is the primary review surface. Also inspect the commit list, diff statistics, renamed files, generated files, submodules, and binary changes so important changes hidden by a convenient UI are not missed. If the working tree is dirty, keep its staged and unstaged changes separate from the committed branch diff and state whether they were included.

Refresh remote refs when authorized and practical. If the base or PR head may be stale and cannot be refreshed, disclose that limitation instead of presenting the review as current. For very large diffs, inventory every changed file first, then examine coherent groups without skipping low-visibility files such as configuration, migrations, manifests, lockfiles, build scripts, and CI definitions.

## Analyze the Change in Repository Context

Do not review isolated hunks only. Read the changed code in full and trace the relevant callers, callees, types, tests, public exports, configuration, persistence formats, and error paths. Search the repository for consumers of altered names, signatures, behavior, schemas, environment variables, and package entry points.

Prioritize issues that can affect correctness, reliability, security, operability, or users of the code:

- behavior that differs from the PR's stated intent or from established invariants
- unhandled boundary values, empty or malformed inputs, partial failures, retries, concurrency, ordering, or platform differences
- state corruption, data loss, unsafe migrations, resource leaks, or non-atomic updates
- incorrect assumptions about API responses, filesystem state, clocks, locales, encodings, or network behavior
- missing validation or error propagation and failures that are silently swallowed
- tests that miss the changed behavior or assert an implementation detail while the regression remains possible
- maintainability problems only when they create a concrete defect risk; avoid style-only findings already covered by automated tooling

### Compatibility and Consumers

Treat every externally consumed surface as a contract. Check public APIs, exported types, CLI flags and output, configuration keys and defaults, environment variables, serialization and database formats, events, network protocols, package entry points, supported runtimes, and deployment or build behavior.

Look for downstream consumers both inside and outside the immediate package. Consider source, binary, behavioral, and data compatibility; upgrade and rollback paths; mixed-version deployments; deprecation policy; and whether documentation, migrations, versioning, or release notes are required. A passing test suite does not make an undocumented breaking change safe.

## Verify Findings

Run focused tests, type checks, linters, or builds when they materially validate a suspected issue and are safe in the repository. Start with the narrowest useful command. Treat CI status as evidence, not a substitute for code analysis, and distinguish failures introduced by the branch from known or unrelated failures.

Before reporting a finding:

1. Confirm it is introduced by the reviewed diff.
2. Trace a realistic input or execution path that triggers it.
3. Check nearby code and tests for a guard or invariant that disproves it.
4. Identify the user, developer, service, or package consumer affected.
5. Point to the smallest relevant changed line or hunk.

Do not report speculative concerns as defects. If evidence is incomplete but the risk is important, label it as a question or residual risk and say what could confirm it.

## Report the Review

Lead with findings, ordered by severity. For each finding, include:

- a severity such as `P0`, `P1`, `P2`, or `P3`
- a concise title describing the failure
- a changed file and line reference
- the triggering scenario and why current behavior is wrong
- the concrete impact on users, developers, operations, or downstream consumers

Keep each finding self-contained and actionable. Combine findings with the same root cause. Do not bury defects in a general summary, inflate severity, or pad the review with praise and narration.

After the findings, briefly state what was reviewed, relevant check or test status, and any limitations. If there are no actionable findings, say so explicitly while still noting unverified areas or unavailable CI/PR context.
