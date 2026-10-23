---
name: rerun-flaky-ci
description: Babysit a pull request's flaky CI by rerunning its failed GitHub Actions jobs until every check passes, up to 15 reruns, then report back. Use when the user links a pull request and asks to rerun, retry, or babysit flaky or failing CI, or runs /rerun-flaky-ci.
argument-hint: <pr url> [max reruns]
---

# Rerun Flaky CI

The bundled `rerun-flaky-ci` script next to this file (`~/.agents/skills/rerun-flaky-ci/rerun-flaky-ci`) runs the whole loop deterministically:

1. Wait until every check on the pull request has finished.
2. If they all passed, stop.
3. Otherwise rerun only the failed and cancelled jobs of each failed GitHub Actions run (`gh run rerun <run-id> --failed`), wait for those runs to finish, and go back to step 1.
4. Give up after 15 reruns.

It only reruns CI. Never push, comment on the pull request, or change code as part of this skill.

## Start It

1. Take the pull request URL from `$ARGUMENTS`. A number or branch also works when this session is inside that repository. If there is none, ask for it.
2. If `$ARGUMENTS` gives a different try count, pass it as `--max-reruns <n>`.
3. Start the script as a background command of this session that notifies you when it exits. It can run for hours, so do not run it in the foreground, and do not poll its output while it runs.

   ```sh
   ~/.agents/skills/rerun-flaky-ci/rerun-flaky-ci <pr url>
   ```

4. Tell the user it is running and stop until it exits.

Other options:

| Option | Default | Effect |
|---|---|---|
| `--max-reruns N` | `15` | Rerun rounds before giving up. |
| `--interval SECONDS` | `60` | How often it polls GitHub. |
| `--round-timeout MINUTES` | `180` | How long one round may stay pending before it stops. |
| `--required` | off | Only wait on and rerun the checks the branch protection requires. |
| `--dry-run` | off | Print the current checks and what would be rerun, then exit without rerunning anything. |

## Report

When the script exits, read its output. The last line starts with `RESULT:`, and the block above it lists the checks still failing and how many rounds each check failed in. Report by exit code:

- **0, passed:** say it passed and how many reruns it took. Name every check that failed in any round, since those are the flaky ones worth fixing.
- **1, still failing after the last rerun:** list the failing checks with their links. Read the latest failure with `gh run view <run-id> -R <host/owner/repo> --log-failed` and say whether it looks like a real failure rather than a flake. Do not start another round unless the user asks.
- **2, stopped:** say why, in the script's words. Usually a failing check that is not a GitHub Actions run and cannot be rerun, checks pending past the round timeout, no checks at all, or GitHub refusing the rerun.
- **3, the pull request changed:** a new push moved its head commit, or it was closed or merged. Offer to start again on the new head.
