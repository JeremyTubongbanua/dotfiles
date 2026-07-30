---
name: devdoc
description: >
  Use this skill when writing or updating a per-package developer doc under
  packages/<package>/docs/<topic>.md — architecture direction docs that
  explain where a subsystem is heading and why, not how to use it (that's
  README.md's job). Trigger on requests like "document this decision", "write
  a devdoc for X", "add a docs/ page explaining Y", or when a change makes a
  future reader (including an AI agent) able to "fix" something back to its
  old shape without knowing it was deliberate. Also use when reviewing an
  existing devdoc for staleness, or splitting one that has grown past ~100
  lines or drifted across packages.
license: BSD-3-Clause
compatibility: Claude Code and any agentskills.io-compatible agent.
user-invocable: true
metadata:
  version: "1.0.0"
  last_modified: "Thu, 30 Jul 2026 00:00:00 GMT"
---

# devdoc Skill

> **Audience:** anyone writing a `packages/<package>/docs/<topic>.md` file in
> this SDK repo — including an AI agent about to touch the code it documents.

Source of truth: [`docs/packages/devdoc_template.md`](../../../docs/packages/devdoc_template.md).
If this skill and that file ever disagree, the template wins.

---

## 1. What a devdoc is — and isn't

A devdoc explains where a subsystem is **heading** and which decisions got it
there, so the next person doesn't reopen a settled question or "fix"
something deliberate.

|          | `README.md`               | `docs/<topic>.md`                      |
| -------- | -------------------------- | --------------------------------------- |
| Audience | Consumer of the package    | Developer working on/against it         |
| Answers  | "How do I use this?"       | "Why is it built this way? What's left?" |

If you're about to explain usage, write a README. If you're about to explain
a decision, a tripwire, or a half-finished migration, write a devdoc.

## 2. Before writing

1. **Check for an existing doc on this topic** — `ls packages/<package>/docs/`
   and extend it rather than duplicating.
2. **One topic per file**, named for the question it answers
   (`pkam-signing.md`, `atkeys-file-format.md`), not a broad category
   (`auth.md`).
3. **Does the change span packages?** Each package's `docs/` covers its own
   side. State shared rationale once, in the package that owns the thing,
   and link to it from the other side with a relative link.

## 3. The rules, while drafting (not after)

1. One topic per file. Split rather than nest.
2. Short — past ~100 lines you're restating the source. Link to code
   instead; dartdoc owns per-method contracts.
3. Every decision carries its reasoning **and** its rejected alternative,
   where one existed. A decision without a why gets undone.
4. Say what isn't done — half-finished migrations, deferred protocol
   questions, semver caveats are the highest-value content, and the part
   nobody else writes down.
5. Every section stands alone. Readers arrive from links and greps, not the
   top. Repeat the subject noun: "`FileAtKeysIo.write` throws…", not "it
   throws…".
6. Present tense, no history — "we recently changed" belongs in the
   CHANGELOG, not here.
7. Point at files; don't inline long snippets. One short usage snippet earns
   its place; a walkthrough doesn't.
8. Cite real paths — `lib/src/keys/io/file_io.dart`, not "the file IO class".
   Cross-package links are relative: `../../at_lookup/docs/pkam-signing.md`.
9. Own the split — shared rationale lives once, in the owning package.
10. Preserve domain capitalisation: atsign, atServer, atKey, `.atKeys`,
    APKAM, PKAM, CRAM, Atsign Protocol.
11. Update the doc in the same PR that changes the code. A stale doc is
    worse than no doc — it gets trusted anyway.

## 4. Copy this template

Target path: `packages/<package>/docs/<topic>.md`

```markdown
# <Subsystem or feature> — direction and decisions

Status: <landed in \<package\> \<version\> | in progress | superseded by …>.
<Add "Migration incomplete." or similar if it applies.>

<If the change spans packages: one line naming what lives in the other
package, with a relative link to its doc.>

## Direction

<Where this subsystem is going and what problem that solves. Lead with
what was wrong with the previous shape — concretely, not "it was
messy". 2–3 short paragraphs.>

<Optional: the smallest snippet that shows the intended usage.>

## Decisions

**<The decision, as a claim.>** <Why. The alternative that was rejected
and what it would have cost. 2–4 sentences.>

**<Next decision.>** <Why.>

<Include decisions a reader might otherwise undo: deliberate throws,
intentional deprecation-over-removal, values that are load-bearing for
wire or file compatibility. Say plainly when something is a tripwire.>

## Not done yet

- <Unmigrated callers, and what their migration unblocks.>
- <Deferred questions and who has to answer them.>
- <Semver caveats — including ones the version bump understates.>

## Reference

- `lib/src/<path>.dart` — <what a reader finds there>
- `test/<path>_test.dart` — <what it pins down>
```

## 5. Self-check before committing

- [ ] Filename answers a question, not a category
- [ ] Every decision has a "why", and a rejected alternative where one existed
- [ ] "Not done yet" is non-empty, or explicitly says nothing is pending
- [ ] No section assumes the reader arrived from the top of the file
- [ ] No history language ("we recently…") — that's the CHANGELOG's job
- [ ] Every cited path is real — grep it if unsure
- [ ] Domain terms capitalised: atsign, atServer, atKey, `.atKeys`, APKAM,
      PKAM, CRAM, Atsign Protocol
- [ ] This doc lands in the same PR as the code it describes
