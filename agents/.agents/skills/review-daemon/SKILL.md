---
name: review-daemon
description: Orchestrate pull request reviews. Keep watching GitHub for pull requests that request the user's review or are assigned to them, start a fresh Claude session for each in its own herdr tab that runs /code-review and then asks the user there whether to post it, and keep the user up to date with a summary of what each review tab is doing. Use when the user runs /review-daemon or asks to watch for, auto-review, or keep up with incoming review requests.
argument-hint: "[pr url] [--interval SECONDS] [--teams] [--max-active N]"
---

# Review Daemon

This session is the orchestrator. The bundled `review-daemon` script next to this file (`~/.agents/skills/review-daemon/review-daemon`) does the GitHub polling and herdr work deterministically. The watcher runs in its own `review daemon` tab in this session's herdr workspace, never in this session's background, so closing the workspace or pressing Ctrl+C in that tab stops it. This session waits for the watcher's events and tells the user what each review tab is doing.

Each review tab owns its pull request. When its review is done, it shows the review there and asks the user whether to post it as a comment, post it as a review, or skip it. Never review a pull request, post, comment, submit a review, or ask about posting in this session. Point the user to the tab instead.

## What the Watcher Does

- Every 2 minutes it searches GitHub for open, non-draft pull requests that request the user's review directly or are assigned to them by someone else. `--teams` also includes requests made to the user's teams.
- Every waiting pull request it has not reviewed yet gets reviewed, including ones that were already waiting before the daemon first ran and ones that arrived while no watcher was running.
- Each new pull request gets its own tab in this session's herdr workspace, opened in this session's directory without taking focus. It never opens a workspace. The tab is named after the project: the repository owner up to its first `-`, so `atsign-company` and `atsign-foundation` give `atsign claude` and `align-company` gives `align claude`, while the user's own repositories give `personal claude`. Claude starts there with `/code-review <url>`, saves the finished comment to a file, then asks the user in that tab whether to post it.
- A pull request that leaves the queue and comes back, for example after a re-request, is reviewed again.
- A benched pull request is never reviewed, even when review is requested again, until it is unbenched. The watcher also stops reporting on its tab.
- At most 3 reviews run at once. Others are queued until a slot frees.
- State lives in `~/.local/state/review-daemon/`, one folder per pull request holding the prompt, the review, and the herdr tab and pane.

The watcher keeps running and appends one line per event to `~/.local/state/review-daemon/events`, which it also prints in its tab. `review-daemon events` waits until there are events this session has not seen yet, prints them, and exits 0. It exits 3 with a `STOPPED:` line when the watcher is no longer running, so it never outlives the watcher by more than a few seconds.

| Event | Meaning |
|---|---|
| `READY <url> <file>` | The review is written, and its tab is asking the user whether to post it. |
| `ATTENTION <url> <reason>` | The review session is stuck on a permission prompt or question, has sat idle for 10 minutes without writing a review, or claude is no longer running in its pane. |
| `FAILED <url> <reason>` | The review could not start, or its pane closed before the review was written. |
| `ERROR: <reason>` | The watcher stopped. Examples: gh is not authenticated, or GitHub was unreachable for an hour. |
| `STOPPED: <reason>` | The watcher is not running, for example after Ctrl+C in its tab or its tab or workspace closing. |

## Summarise the Tabs

Run `review-daemon list`. Its first line says whether the watcher is running and in which tab. For each pull request it prints the status, title, tab, what claude in that tab is doing right now, the review file, and its findings. Pull requests waiting for a slot print as `queued`. Benched pull requests show `benched: yes`, or print as `benched` when they were never reviewed.

Turn that into one table with a row per pull request: the tab (label and id, such as `atsign claude (wA:t8)`), the pull request as a Markdown link to its URL (`[repo#number](url)`) followed by its title, and what it is doing in plain words. Every pull request you mention, in the table or in the event lines above it, links to its URL.

| Status | Say |
|---|---|
| `reviewing` | reviewing, with what the tab says it is doing; note it if claude is blocked, idle, or not running |
| `ready` | done, waiting for the user's decision in that tab |
| `posted` | posted |
| `skipped` | skipped |
| `failed` | failed, with the reason |
| `queued` | waiting for a free slot |

Put the rows that need the user first: `ready` tabs and anything with an `attention` line. Leave benched pull requests out of the table. Instead, end the summary with one line linking each benched pull request.

Under the table, list the findings of every pull request that has a review, in the same order as the table. Head each group with the pull request's link and title, then one line per `findings` entry from `review-daemon list`, giving its priority and title, such as `P1: ESP32 build fails because bootloader_random_enable() is undeclared`. Write `no findings` for a review without any. Never only point at the review file.

## Start

1. Check that `HERDR_ENV` is `1`. If not, say the daemon has to run inside a herdr pane and stop.
2. If `$ARGUMENTS` names a pull request URL, start its review now with `review-daemon dispatch <url>`.
3. Start the watcher in its tab, passing along any options from `$ARGUMENTS`. This opens a `review daemon` tab without taking focus, or reuses the one from an earlier run, and returns once the watcher is up. If a watcher is already running, it says so and leaves it alone. Never run `review-daemon watch` from this session.

   ```sh
   ~/.agents/skills/review-daemon/review-daemon start [--interval SECONDS] [--teams] [--max-active N]
   ```

4. Start the event waiter as a background command of this session that notifies you when it exits. Do not poll its output.

   ```sh
   ~/.agents/skills/review-daemon/review-daemon events
   ```

5. Give the user the summary of the tabs, say the daemon is watching in the `review daemon` tab, then stop until the waiter exits.

## When the Event Waiter Exits

1. Read its output.
2. If it exited with code 0 and printed no `ERROR:` line, start `review-daemon events` again right away in the background, before anything else. Events already reported are not reported again.
3. Lead with what changed, one line per event:
   - `READY`: the review of that pull request is done, and its tab is waiting for the user to decide whether to post it.
   - `ATTENTION`: which pull request, why, and which tab to look at.
   - `FAILED`: the reason, and offer to retry with `review-daemon dispatch <url>`.
   - `ERROR:`: the watcher stopped and why. Do not restart it until the user says to.
   - `STOPPED:` (exit code 3): the watcher is no longer running. Do not restart it or the waiter until the user says to; `/review-daemon` starts both again.
4. Then give the updated summary of the tabs.

When the user asks how the reviews are going, give the summary of the tabs.

## Bench

When the user says a pull request is old or irrelevant, or asks to bench it, run `review-daemon bench <url>...`. To bring one back, run `review-daemon unbench <url>...`, and the watcher reviews it on its next poll if it is still waiting for the user. `review-daemon dispatch <url>` also unbenches the pull request it starts.

Benching also closes the pull request's review tab, which stops a review that is still running, and marks a running or waiting review as skipped. A review tab's own question also offers Bench, which does the same from inside that tab.

## Stop

When the user asks to stop, run `review-daemon stop`. The event waiter then exits with `STOPPED:` on its own. Leave the `review daemon` tab and every review tab open; the user closes them, and the next `start` reuses the `review daemon` tab.
