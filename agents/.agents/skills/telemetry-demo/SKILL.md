---
name: telemetry-demo
description: >-
  Run the Atsign Control Center telemetry demo on this machine from an atsign_control_center worktree: a local ephemeral environment (EE) whose atServers are built from a local at_server worktree, one Atsign per application plus a collector Atsign, the collector, Loki, the mock registrar and the web service, all in Docker, then the applications themselves, each process in its own tab of one herdr workspace. Use when asked to run, rebuild, restart, update or tear down the local telemetry demo, or to try instrumented atServer, collector, web service or application code end to end.
---

# Telemetry demo

The demo's scripts live in the Control Center repository (`atsign-company/atsign_control_center`, worktrees under `~/GitHub/atsign/atsign_control_center/`) as `tools/deploy/local/demo_*.sh`, next to the EE build files they share with the older `reboot.sh` stack. Generated keys, certificates, config and state go to `tools/deploy/local/.work/demo/`, which git ignores; below, `.work/demo` means that directory in the worktree in use. The scripts find the repository from their own location, so run the copy in the worktree under test. Older branches may not have the `demo_*.sh` scripts yet; use a worktree that has them.

Everything comes from local code:

- the atServer comes from the at_server worktree passed as `--at-server-dir`, compiled into the `at_ephemeral:telemetry` EE image by `tools/deploy/local/build_ee.sh`;
- the collector (`at_telemetry_service`) and the web service (with the frontend) are built from the Control Center worktree's Dockerfiles;
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

5. **Ports 2700-2799, 8080, 13100 and 18090 are free or held by the demo.** `demo_up.sh` checks each component's ports just before starting it. The older `tools/deploy/local/reboot.sh` stack uses the same ports as compose project `telemetry-ee`; tell the user before stopping it, then stop it with `docker compose -p telemetry-ee -f tools/deploy/local/compose.yaml -f tools/deploy/local/ee.compose.yaml down`. That keeps its volumes; never add `--volumes`.

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
- `command`: one line run with `bash -c` in `dir`. It can use `$AT_SIGN`, `$AT_KEYS_FILE` (the onboarded `.atKeys`), `$AT_ROOT_SERVER` (`vip.ve.atsign.zone:2700`), `$AT_COLLECTOR` and `$AT_STORAGE_DIR` (a per-app client storage directory, emptied whenever the EE restarts).
- `every`: seconds between reruns after the command exits, or `0` (the default) to run once. Long-running apps use `0`.

`demo_apps.example.json` runs `packages/monitoring/at_telemetry_service/example/at_telemetry_example.dart` as `@alice`, `@bob` and `@charlie` every 60 seconds; each run logs an app event batch to the collector Atsign and waits for its acknowledgement. A branch cut before the example moved there lacks it; point `dir` at a worktree that has it, in a local apps file.

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

1. Checks the prerequisites and writes `.work/demo/config` from the apps file: the EE's Atsign list (apps then collector), `producers.json`, `registrar_atsigns.json` and `apps.tsv`. Files are rewritten in place, so running containers keep seeing them.
2. Rebuilds the images of the selected components: the EE from `--at-server-dir`, the collector and web service from the worktree. Docker's cache makes unchanged builds fast; never skip this, because stale images are the usual reason a code change does not show up.
3. Compares each container's `telemetry-demo.spec` label, a hash of its image ID, its config files and the worktree path, with what it should be. A component is restarted when the hash differs, its container is not running, its tab is not running it, or it is named in `--restart`. Restarting stops the process in the existing tab with Ctrl+C and reruns the command there; a tab is created only when its label is missing, and closed only when the Atsign or app it served is gone.
4. When the EE restarts, every Atsign is onboarded again with `at_activate`, the keys and EE certificates are copied to `.work/demo`, and the atServers are restarted to sign telemetry with the new keys. New keys mean the collector, the `atserver @<name>` log tails and the apps restart too, whatever `--only` says.
5. Apps restart when their apps-file entry changed, the EE restarted, or (for apps with `every` above 0) their tab stopped.
6. Waits for heartbeats when the EE, collector or Loki restarted, and for application telemetry from restarted apps, then prints what restarted and what was up to date, and ends with `DEMO READY: http://localhost:8080`.

What to run after a change:

| Changed | Command | Tabs touched |
| --- | --- | --- |
| Web service or frontend | `demo_start.sh --only web` | `web` |
| Collector | `demo_start.sh --only collector` | `collector` |
| `mock_registrar.dart` | `demo_start.sh --only registrar` | `registrar` |
| An app's code | `demo_start.sh --only apps --restart apps` | `app <name>` |
| The web service settings file | `demo_start.sh --only web --restart web` | `web` |
| atServer code, the apps file, or not sure | `demo_start.sh` | whatever changed; an EE change also restarts collector, log tails and apps |
| Another worktree | `demo_start.sh` from that worktree, with its inputs | everything, since the worktree path is part of every hash |

The registrar rereads `.work/demo/config/registrar_atsigns.json` on every request, so changing `--email` needs no restart.

A full first run takes several minutes, mostly compiling. Follow it without polling in a tight loop: wait on the setup pane, for example `herdr pane wait-output <setup pane> --regex 'DEMO READY|Timed out|is in use|must |No |not running|error' --timeout 900000`, then `herdr pane read <setup pane> --source recent-unwrapped --lines 80`. `wait-output` also matches text already on screen, so after a rerun read the pane rather than trusting an old `DEMO READY`. If a step fails, read that step's tab (`herdr tab list --workspace <id>`, then `herdr pane read` its root pane) before changing anything.

## Check it

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/healthz
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:13100/ready
docker ps --filter label=telemetry-demo --format '{{.Names}} {{.Status}} {{.Label "telemetry-demo.spec"}}'
```

The first two print `200`. Records in Loki for one producer, for example `@alice`:

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
