---
name: telemetry-demo
description: >-
  Run the Atsign Control Center telemetry demo on this machine from an atsign_control_center worktree: a local ephemeral environment (EE) whose atServers are built from a local at_server worktree, one Atsign per application plus a collector Atsign, the collector, Loki, the mock registrar and the web service, all in Docker, then the applications themselves (including a chat between APKAM enrollments and the management backend and frontend on EE Atsigns), each process in its own tab of one herdr workspace. Use when asked to run, rebuild, restart, update or tear down the local telemetry demo, to try instrumented atServer, collector, web service, management or application code end to end, and after changing code that a running demo serves, so the user can see the change.
---

# Telemetry demo

The demo's scripts live in the Control Center repository (`atsign-company/atsign_control_center`, worktrees under `~/GitHub/atsign/atsign_control_center/`) as `tools/deploy/local/demo_*.sh`, next to the EE build files they share with the older `reboot.sh` stack. Generated keys, certificates, config and state go to `tools/deploy/local/.work/demo/`, which git ignores; below, `.work/demo` means that directory in the worktree in use. The scripts find the repository from their own location, so run the copy in the worktree under test. Older branches may not have the `demo_*.sh` scripts yet; use a worktree that has them.

Everything comes from local code:

- the atServer comes from the at_server worktree passed as `--at-server-dir`, compiled into the `at_ephemeral:<at_server git hash>` EE image by `tools/deploy/local/build_ee.sh`;
- the collector (`at-telemetry-service:<git hash>`) and the web service with the frontend (`control-center-web:<git hash>`) are built from the Control Center worktree's Dockerfiles (see [Image tags](#image-tags));
- each application runs with `dart run` (or any command) from its own local checkout.

## What runs

One herdr workspace, labelled `telemetry demo`, with one tab per process:

| Tab | Process | Container | Reachable at |
| --- | --- | --- | --- |
| `setup` | `demo_up.sh`, which builds and reconciles everything | none | |
| `loki` | Loki, data in volume `telemetry-demo-loki-data` | `telemetry-demo-loki` | 127.0.0.1:13100 |
| `ee` | supervisord: atDirectory on 2700 and one atServer per Atsign | `telemetry-demo-ee` | 127.0.0.1:2700-2799 |
| `atserver @<name>` | `tail -F` of that atServer's log inside the EE | none (`docker exec`) | |
| `collector` | the collector, signed in as the collector Atsign | `telemetry-demo-collector`, in the EE's network namespace | https vip.ve.atsign.zone:2777 |
| `registrar` | the mock registrar, answering from `.work/demo/config/registrar_atsigns.json` | `telemetry-demo-registrar` | http 127.0.0.1:18090 |
| `web` | the web service and dashboard | `telemetry-demo-web` | http://localhost:8080 |
| `app <name>` | one application, on the host | none | |
| `app management-backend` | the management backend, as the vault Atsign (an app, see [Management](#management)) | none | http://localhost:8090 |
| `app management-frontend` | the management frontend's Vite dev server | none | http://localhost:5173 |

The containers share the Docker network `telemetry-demo`. atServers send signed telemetry to `vip.ve.atsign.zone:2777`, which inside the EE is the collector; applications send telemetry as Atsign notifications to the collector Atsign. The collector forwards both to Loki under tenant `atsign`, which is the tenant the dashboard reads.

Each `demo_service.sh` tab runs its container in the foreground with `--rm` and removes it on Ctrl+C or when the tab closes. Closing the workspace sends SIGHUP to every tab, so it removes every demo container. Volumes are never removed, so Loki history survives. Host processes (apps, log tails) die with their tab.

## Keep the data

The telemetry history in Loki belongs to the user and outlives every demo run. Tearing down, restarting, rebuilding, switching worktrees and troubleshooting all keep it. Delete it only when the user explicitly asks, in the current request, to drop the history. Without that request:

- never pass `--wipe-loki` to `demo_start.sh` or `demo_up.sh`;
- never run `docker volume rm telemetry-demo-loki-data`, `docker volume prune`, `docker system prune --volumes` or `docker compose ... down --volumes`;
- never run `reboot.sh --wipe-loki` or `reset_loki_and_build.sh`; both delete the older stack's Loki volume (`telemetry-ee_loki-data`);
- never use Docker Desktop's Clean / Purge data or Reset to factory defaults; both delete every volume.

An empty dashboard, a failed start or a stuck Loki is not a reason to wipe. Restart the component instead, for example `demo_start.sh --only loki --restart loki`. If wiping really looks like the only fix, explain why and ask first.

Loki keeps everything. `loki-config.yaml` turns no retention on, and the write-ahead log is in the volume (`/loki/wal`), so logs Loki had not flushed when it stopped come back on the next start.

Other demo state is not kept, and that is expected. The atServers' storage lives in the EE container, so an EE restart onboards every Atsign again with new keys. It also replaces `.work/demo/keys`, `.work/demo/certs` and `.work/demo/storage`, and the collector starts with empty client storage. None of this touches Loki, and the dashboard keeps each Atsign's history because it looks producers up by Atsign name. A plain `demo_start.sh` restarts the EE when `atsigncompany/ephemeral:latest` changed upstream. When the user wants the EE and its keys left alone, pass `--only` without `ee`.

## Before starting

1. **Pick the inputs.** Ask the user for anything you cannot infer:
   - **Control Center worktree** whose code the collector and web service are built from, and whose scripts you run.
   - **at_server worktree** to build the atServer from, for example `~/GitHub/atsign/at_server/jt/atserver-telemetry`. It must contain the telemetry code; with `git -C <dir> log -1` and `git -C <dir> status --short`, tell the user which commit and uncommitted changes will be built.
   - **Google account email** the user signs in to the dashboard with. The mock registrar maps it to every app Atsign. The git author email is often a different account; ask when unsure.
   - **Applications**, see below. The default is `tools/deploy/local/demo_apps.example.json`.

   `demo_up.sh` saves the at_server worktree, emails and apps file in `.work/demo/state`, so later runs from the same worktree can leave them out.
2. **Docker Desktop is running.** `docker info`; otherwise `open -a Docker` and wait for `docker info` to succeed.
3. **`vip.ve.atsign.zone` resolves to 127.0.0.1 on the host** (`dscacheutil -q host -a name vip.ve.atsign.zone`). Apps on the host reach the EE through it. If it does not, ask the user to add `127.0.0.1 vip.ve.atsign.zone` to `/etc/hosts`; do not edit it yourself.
4. **The web service settings file exists.** List `packages/monitoring/web_service/` with `ls -a` and look for `.env`. Never read, print, grep, copy or edit `.env` or `.env.*` files, and never name their paths in your own commands; the harness denies it. The `web` container mounts the file read-only and the service reads it. If it is missing, ask the user to copy it from a worktree that has one, for example:

   ```bash
   ! cp \
     ~/GitHub/atsign/atsign_control_center/trunk/packages/monitoring/web_service/.env \
     <this worktree>/packages/monitoring/web_service/.env
   ```

5. **Ports 2700-2799, 8080, 13100 and 18090 are free or held by the demo**, and 8090 and 5173 too when the apps file runs the management app. `demo_up.sh` checks each component's ports just before starting it. The older `tools/deploy/local/reboot.sh` stack uses the same ports as compose project `telemetry-ee`; tell the user before stopping it, then stop it with `docker compose -p telemetry-ee -f tools/deploy/local/compose.yaml -f tools/deploy/local/ee.compose.yaml down`. That keeps its volumes; never add `--volumes`.

## Applications

An apps file is JSON. Each app gets its own Atsign, onboarded in the EE, and its own tab:

```json
{
  "collector": "@telemetry_collector_local",
  "apps": [
    {
      "name": "alice",
      "atsign": "@alice",
      "dir": "packages/monitoring/at_telemetry_service",
      "command": "dart run example/at_telemetry_example.dart -a $AT_SIGN -k $AT_KEYS_FILE -r $AT_ROOT_SERVER -s $AT_STORAGE_DIR -c $AT_COLLECTOR",
      "every": 60
    }
  ]
}
```

- `name`: unique, `a-z`, `0-9`, `-`, `_`; the tab is `app <name>`.
- `atsign`: lower case, `a-z`, `0-9`, `_`. One Atsign per app is the norm (three apps, three atServers); two apps may share one. It must differ from `collector`.
- `dir`: the app's local checkout, absolute, `~/...`, or relative to the Control Center worktree.
- `command`: one line run with `bash -c` in `dir`. It can use `$AT_SIGN`, `$AT_KEYS_FILE` (the onboarded `.atKeys`, or the app's own enrollment keys when it has `enrollment`), `$AT_ROOT_SERVER` (`vip.ve.atsign.zone:2700`), `$AT_COLLECTOR` and `$AT_STORAGE_DIR` (a per-app client storage directory, emptied whenever the EE restarts).
- `every`: seconds between reruns after the command exits, or `0` (the default) to run once. Give long-running apps a small value such as `5`: they never exit on their own, so it only sets how soon a crashed app comes back, and the reconcile reruns their tab if it stopped.
- `enrollment` (optional): `{"app": "chat", "device": "phone", "namespaces": {"my_app": "rw", "at_telemetry": "rw"}}`. The app runs as its own APKAM enrollment of `atsign` instead of the onboarded keys. `demo_enroll.sh` creates it in the EE (it sets a semi-permanent passcode with the onboarded keys, runs `at_activate auto` to approve the matching request, then `at_activate enroll`) and saves the keys as `.work/demo/keys/enrollments/<name>.atKeys`. It enrolls again only when the EE restarted or the entry changed. Include `at_telemetry: rw` whenever the app sends telemetry, since its notifications to the collector use that namespace.
- `telemetry` (optional, default `true`): `false` for apps that send no application telemetry, such as the management app, so the reconcile does not wait 90 seconds for it.

At the top level, two optional lists add Atsigns that no app uses:

- `spare_atsigns`: the EE creates them but the demo never onboards them, so the management app can spawn them. They are in the producers file and the registrar answer, so they show on the dashboard once spawned.
- `silent_atsigns`: provisioned in the EE (its atServer runs) but never onboarded, so it has no keys at all, and listed as the user's (registrar), to show an Atsign that does not report next to ones that do. Not onboarding alone does not silence it: an unonboarded atServer of this build still sends signed heartbeats, as the spares do. So after onboarding the others, `demo_up.sh` also adds `environment = AT_TELEMETRY_ENDPOINT=""` to its supervisord program in the EE and restarts it (an empty endpoint turns the atServer's telemetry off), and leaves it out of the producers file so the collector refuses the `started` event it sends before that. Loki then holds nothing from it, and the dashboard lists it with no telemetry and the Connections page counts it as not reporting. Check with `docker exec telemetry-demo-ee supervisorctl status`, where it runs like the others. A silent Atsign cannot be an app's `atsign`.

`demo_apps.example.json` runs `packages/monitoring/at_telemetry_service/example/at_telemetry_example.dart` as `@alice`, `@bob` and `@charlie` every 60 seconds; each run logs an app event batch to the collector Atsign and waits for its acknowledgement. A branch cut before the example moved there lacks it; point `dir` at a worktree that has it, in a local apps file.

### Chat demo

`demo_apps.chat.example.json` runs `packages/monitoring/at_telemetry_service/example/at_message_relay_example.dart`, a long-running client that sends and receives plain notifications (`message.at_message_relay_example`) and logs each one as application telemetry:

- `alice-phone` and `alice-laptop` are two APKAM enrollments of `@alice` (app `chat`, devices `phone` and `laptop`, namespaces `at_message_relay_example:rw` and `at_telemetry:rw`). Each sends `@bob` a message about every 10 and 15 seconds (`--send-to @bob --interval N --label phone`).
- `alice-phone` holds exactly one connection: `--never-sync` (a `CLIBase` flag) drops the sync connection and `--no-listen` drops the monitor, so it only sends. `alice-laptop` keeps the defaults, a command connection plus a monitor, so the Connections page shows the two devices side by side.
- `bob-chat` (`--reply --forward-to @charlie`) answers every message to its sender and forwards it to `@charlie`. A reply to `@alice` reaches every enrollment that listens, so the `alice-laptop` tab shows the replies to the phone too.
- `charlie-chat` only listens.

The relay's flags are `--send-to`, `--forward-to`, `--reply`, `--[no-]listen`, `--label` and `--interval` (average seconds, each wait picked from half to one and a half times it), plus `CLIBase`'s own such as `--never-sync`. When `enroll` runs, `at_activate` holds one more connection of the enrollment for a moment; it closes once the enrollment is approved. Because these clients hold their connections open, the dashboard's devices, Connections page and timeline show them as connected. After an EE restart the atServers log a burst of `auth.failed` (`enrollment_expired`) events from clients still holding the old keys and from `at_activate enroll` waiting for approval; that is expected and stops once the apps restart.

The example also runs the management app, spares `@dave` and `@erin`, and the silent `@quiet`; drop those entries for a chat-only demo. For the user's own mix (for example the per-minute batch apps from another worktree plus the chat), copy it to `tools/deploy/local/demo_apps.<name>.local.json`.

### Management

The management backend (`packages/management/backend`) and frontend (`packages/management/frontend`) run as two apps sharing the vault Atsign, normally `@vault`:

```json
{"name": "management-backend", "atsign": "@vault", "dir": "packages/management/backend",
 "command": "dart run bin/management_backend.dart -a $AT_SIGN -k $AT_KEYS_FILE --root-domain $AT_ROOT_SERVER --port 8090 --company-name 'Demo Company'",
 "every": 5, "telemetry": false},
{"name": "management-frontend", "atsign": "@vault", "dir": "packages/management/frontend",
 "command": "test -d node_modules || npm ci --no-audit --no-fund; MANAGEMENT_BACKEND_ORIGIN=http://localhost:8090 exec npm run dev -- --port 5173 --strictPort",
 "every": 5, "telemetry": false}
```

- The backend listens on 8090, because the dashboard has 8080. The frontend at http://localhost:5173 proxies `/v1` to `MANAGEMENT_BACKEND_ORIGIN` (`vite.config.ts` reads it; without it the proxy goes to 8080). Check the pair with `curl -s http://localhost:5173/v1/audit`, which prints `[]` on a fresh vault.
- `--root-domain vip.ve.atsign.zone:2700` needs the backend's `AtClientPool` to parse the port (`AtRootDomain.parse`); a branch without that fix connects to port 64 and fails.
- There is no sign-in; the frontend asks for a name and records it with every change. The list of managed Atsigns comes from the audit log.
- To spawn an Atsign, the user needs a spare one (from `spare_atsigns`) and its CRAM secret. The EE's secrets are throwaway test values; read one with `docker exec telemetry-demo-ee awk '$1 == "dave" {print $2}' /tmp/CRAM_Keys` and give it to the user for the Spawn dialog. Never use a spare Atsign as an app's `atsign`, since the demo would onboard it first.
- A freshly spawned atServer was started before it had keys. If its heartbeats do not reach the dashboard, restart it: find its program with `docker exec telemetry-demo-ee supervisorctl status`, then `docker exec telemetry-demo-ee supervisorctl restart <program>`.
- Backend code changes need its tab restarted (see [After changing code](#after-changing-code)); the frontend's Vite server reloads `src/` changes by itself.

For another app, such as a chat app on a local branch, write an apps file with that app's checkout as `dir` and its own command line. Keep it outside `.work/demo`; `tools/deploy/local/demo_apps.<anything>.local.json` is ignored by git. The app must take an Atsign, a key file and a root server (`at_cli_commons` `CLIBase` apps take `-a`, `-k`, `-r`, `-s`). For its telemetry to reach the dashboard it must send `at_telemetry` notifications to `$AT_COLLECTOR`; atServer telemetry (heartbeats, connection events and the rest) arrives whatever the app sends. The EE's certificate for `vip.ve.atsign.zone` is publicly trusted, so apps need no extra CA settings. Run `dart pub get` in the app's checkout first if it has never been resolved.

## Start or update

From the Control Center worktree under test:

```bash
tools/deploy/local/demo_start.sh \
  --at-server-dir ~/GitHub/atsign/at_server/jt/atserver-telemetry \
  --email you@example.com \
  [--apps <apps file>] [--only <components>] [--restart <components>] [--wipe-loki]
```

Components are `loki`, `ee`, `collector`, `registrar`, `web` and `apps`, comma-separated. `--wipe-loki` deletes all Loki history before starting; pass it only when the user explicitly asks (see [Keep the data](#keep-the-data)).

`demo_start.sh` never starts a second demo. It looks for herdr workspaces labelled `telemetry demo`:

- none: it creates one, with a `setup` tab;
- one or more: it reuses the first, closes the others (their containers would clash with this one's) after their containers are gone, stops whatever still runs in the `setup` tab, creating the tab if it is missing.

It then runs `demo_up.sh` in the `setup` tab and prints the workspace and setup pane IDs. `demo_up.sh` reconciles the demo with the code, restarting only what changed:

1. Checks the prerequisites and writes `.work/demo/config` from the apps file: the EE's Atsign list (apps, silent, spares, then collector), the Atsigns to onboard, the silent ones, `producers.json`, `registrar_atsigns.json`, `apps.tsv`, `enrollments.tsv` and `quiet_apps`. Files are rewritten in place, so running containers keep seeing them.
2. Rebuilds the images of the selected components, tagged with git hashes (see [Image tags](#image-tags)): the EE from `--at-server-dir`, the collector and web service from the worktree. Docker's cache makes unchanged builds fast; never skip this, because stale images are the usual reason a code change does not show up.
3. Compares each container's `telemetry-demo.spec` label, a hash of its image ID, its config files and the worktree path, with what it should be. A component is restarted when the hash differs, its container is not running, its tab is not running it, or it is named in `--restart`. Restarting stops the process in the existing tab with Ctrl+C and reruns the command there; a tab is created only when its label is missing, and closed only when the Atsign or app it served is gone.
4. When the EE restarts, every Atsign except the spare and silent ones is onboarded again with `at_activate`, the keys and EE certificates are copied to `.work/demo`, the silent Atsigns' telemetry is turned off, and the atServers are restarted to sign telemetry with the new keys. New keys mean the collector, the `atserver @<name>` log tails and the apps restart too, whatever `--only` says. Changing which Atsigns are onboarded or silent also restarts the EE.
5. Apps with an `enrollment` are enrolled (or found already enrolled for this EE) just before their tab is checked. Apps restart when their apps-file entry or enrollment changed, the EE restarted, or (for apps with `every` above 0) their tab stopped.
6. Waits for heartbeats when the EE, collector or Loki restarted, and for application telemetry from restarted apps other than `telemetry: false` ones, then prints each image (`Images`), what restarted and what was up to date, and ends with `DEMO READY: http://localhost:8080`.

The registrar rereads `.work/demo/config/registrar_atsigns.json` on every request, so changing `--email` needs no restart.

### Image tags

Every image the demo builds is tagged with the git hash of the code in it: the first 12 characters of `HEAD` of the worktree it is built from, plus `-dirty` when the paths copied into the image have uncommitted or untracked changes.

| Image | Hash of | Paths checked for `-dirty` |
| --- | --- | --- |
| `at_ephemeral:<tag>` | the at_server worktree | `packages/at_secondary_server`, `packages/at_persistence_secondary_server`, `packages/at_server_spec` |
| `at-telemetry-service:<tag>` | the Control Center worktree | `packages`, `pubspec.yaml`, `pubspec.lock` |
| `control-center-web:<tag>` | the Control Center worktree | the same |

- `demo_up.sh` records each image it builds in `.work/demo/state/image-<ee|collector|web>`, and `demo_service.sh` runs whatever is recorded there; it stops with `No <component> image recorded` when there is none, which `demo_start.sh` fixes by building it. `build_ee.sh` takes the tag as `EE_IMAGE` and defaults to `at_ephemeral:telemetry`, the tag the older `reboot.sh` stack runs.
- A container restarts only when its image's content changes, not when only the tag does: a commit with no other change builds the same image under a new tag, and the running container keeps the tag it started with until the next real change. The `Images` lines at the end of the setup output always show the newest tags; `docker ps` shows the tag each container started with.
- After each run, the hash-tagged images of the rebuilt components that are no longer recorded are removed (`docker image rm`, which skips one a container still uses). Only tags of 12 hex characters, with or without `-dirty`, are removed, so `at_ephemeral:telemetry` and other tags stay. A `-dirty` tag moves to each new dirty build; the image it leaves behind becomes dangling, which `docker image prune` clears.

## After changing code

When a `telemetry demo` workspace is running (`herdr workspace list`) and you have just changed code it serves, the user expects to see the change there without asking. Once the change passes its tests, redeploy only what it touches, from the worktree the demo runs (`.work/demo/state` holds the at_server worktree and apps file it uses):

| Changed | Command | What restarts |
| --- | --- | --- |
| `packages/monitoring/web_service/` or `web_service_frontend/` | `demo_start.sh --only web` | `web`; one image holds both, so a frontend-only change is still this |
| `packages/monitoring/web_service/.env` (the user changes it) | `demo_start.sh --only web --restart web` | `web` |
| `packages/monitoring/at_telemetry_service/` other than `example/` | `demo_start.sh --only collector` | `collector` |
| `tools/deploy/local/mock_registrar.dart` | `demo_start.sh --only registrar` | `registrar` |
| An app's code, such as `at_telemetry_service/example/` or `packages/management/backend/` | `demo_start.sh --only apps --restart apps` | every `app` tab |
| `packages/management/frontend/src/` | nothing; Vite reloads it | |
| `packages/management/frontend/vite.config.ts` or `package.json` | `demo_start.sh --only apps --restart apps` | every `app` tab |
| The at_server worktree the demo builds from | `demo_start.sh` | EE, then collector, log tails and apps (new keys); Loki is kept |
| The apps file, `demo_*.sh`, or not sure | `demo_start.sh` | whatever changed |
| Docs or tests only | nothing | |
| Another worktree | `demo_start.sh` from that worktree, with its inputs | everything, since the worktree path is part of every hash |

Several kinds of change at once: pass every component in one `--only`, such as `--only web,collector`. A change in another Control Center worktree than the one the demo runs from does not reach it; say so instead of switching the demo's worktree on your own.

Then wait for that run's own result (`herdr pane wait-output <setup pane> --regex '\[HH:MM:[0-9]+\] Restarted:'` with the run's start time, since older runs' lines are still on screen), check it (`/healthz` for `web`, the app's tab for an app, a Playwright screenshot of the changed page for UI work), and end by telling the user what restarted and exactly where to look, such as `http://localhost:8080/#/connections`. Restarting `web` drops every dashboard session, so tell the user to sign in again.

A full first run takes several minutes, mostly compiling. Follow it without polling in a tight loop: wait on the setup pane, for example `herdr pane wait-output <setup pane> --regex 'DEMO READY|Timed out|is in use|must |No |not running|error' --timeout 900000`, then `herdr pane read <setup pane> --source recent-unwrapped --lines 80`. `wait-output` also matches text already on screen, so after a rerun read the pane rather than trusting an old `DEMO READY`. If a step fails, read that step's tab (`herdr tab list --workspace <id>`, then `herdr pane read` its root pane) before changing anything.

## Check it

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/healthz
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:13100/ready
docker ps --filter label=telemetry-demo --format '{{.Names}} {{.Image}} {{.Status}} {{.Label "telemetry-demo.spec"}}'
```

The first two print `200`, and the third shows each container with its git-hash image. Records in Loki for one producer, for example `@alice`:

```bash
curl -s -G http://127.0.0.1:13100/loki/api/v1/query_range \
  --data-urlencode 'query={service_name="at_secondary_server"} | at_telemetry_producer_id="@alice"' \
  --data-urlencode "start=$(( $(date +%s) - 600 ))000000000" \
  --data-urlencode 'limit=20'
```

Swap the selector for `{tenant_id="atsign", service_name!="at_secondary_server"} | at_telemetry_producer_id="@alice"` to see application telemetry. Then the user opens `http://localhost:8080` and signs in with the Google account given as `--email`. Restarting `web` drops its sessions, so the user signs in again.

## Tear down

Close the `telemetry demo` workspace. Every container goes, and the Loki volume stays with all the telemetry history. If a container survives (for example after a forced kill), `tools/deploy/local/demo_down.sh` removes every container labelled `telemetry-demo` and nothing else. The `telemetry-demo` network is left in place and reused. A teardown never deletes data.

Drop the Loki history only when the user explicitly asks for it: `docker volume rm telemetry-demo-loki-data` once the demo is down, or `--wipe-loki` on the next start. Before doing either, tell the user it deletes every record shown on the dashboard.

## Troubleshooting

- **`web` exits with `Missing settings: GOOGLE_OAUTH_CLIENT_ID, ...`:** the mounted settings file lacks them; ask the user to fix it. Do not open it.
- **Google sign-in works but the dashboard shows no Atsigns:** the email the user signed in with is not in `.work/demo/config/registrar_atsigns.json`; the `registrar` tab logs each lookup.
- **No heartbeats:** read the `atserver @<name>` tab. An atServer without the telemetry code ignores `AT_TELEMETRY_ENDPOINT`; atServers older than 3.17.0+gha6797 reject `--telemetry_endpoint`. The `collector` tab logs rejected producers.
- **Docker hangs after the disk filled up:** `docker` commands and the engine socket stop answering. Ask the user to free space and restart Docker Desktop; containers do not survive it, so run `demo_start.sh` afterwards. Volumes do survive. Free space with `docker image prune` or `docker builder prune`, never with anything that removes volumes.
- **`build_ee.sh` copies only `at_secondary_server`, `at_persistence_secondary_server` and `at_server_spec`** from the at_server worktree, and its `pubspec_overrides.yaml` replaces that worktree's `dependency_overrides`. Changes to other packages, such as a local `at_telemetry`, need `tools/deploy/local/ee_secondary.Dockerfile` changed too.
- **`build_ee.sh` pulls `atsigncompany/ephemeral:latest` on every build**, so a new upstream EE image restarts the EE (and re-onboards) even when the at_server code did not change. Use `--only` to leave the EE alone.
- **Control Center images ignore `pubspec_overrides.yaml`** and copy only `packages/` (see `.dockerignore`), so local path overrides to sibling repositories do not reach the collector or web service images.
- **TLS failures against `vip.ve.atsign.zone`:** the EE certificate comes from `atsigncompany/ephemeral:latest`; check its expiry with the handshake, not by reading `.work/demo/certs`.
- **A tab's process exited:** run `demo_start.sh` again; the reconcile restarts it in the same tab.
- **A service tab says `No <component> image recorded`:** that component was never built with the hash tags (for example right after updating the scripts); `demo_start.sh --only <component>` builds and records it.
