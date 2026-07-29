---
name: atsign-local-env
description: Stand up a complete local Atsign environment (atDirectory + atServers + Redis) on macOS using Docker — either from the published virtualenv image or built from at_server branch source — and run at_client_sdk tests against it. Use when asked to run a local atDirectory/atServer, test an at_server branch, smoke-test the at_client_sdk locally, or set up the Atsign virtualenv.
---

# Running the Atsign Environment Locally (macOS)

Stands up the "virtualenv" (VE): one Docker container holding the atDirectory
(root server, port 64), ~40 demo atServers (secondaries, ports 25000–25040),
and Redis (6379). Verified working on macOS arm64 with Docker Desktop.

## Repos and layout (worktree collections)

- `~/GitHub/at_server/<worktree>/` — server source (`trunk`, feature worktrees)
- `~/GitHub/at_client_sdk/<worktree>/` — client SDK (pub workspace)

## Prerequisites (verify before starting)

1. **Docker Desktop running**: `docker info` — if it fails, `open -a Docker`
   and poll `docker info` until ready (~20–60 s).
2. **Host Dart SDK**: `dart --version` (3.12+ known good).
3. **/etc/hosts**: `vip.ve.atsign.zone` must resolve to 127.0.0.1
   (public DNS resolves it to 10.64.64.64, which will NOT work):
   `grep vip.ve.atsign.zone /etc/hosts` → expect `127.0.0.1 vip.ve.atsign.zone`.
4. **Free ports**: 64, 443, 6379, 25000–25040 (`docker ps` for stale VEs).

## Path A — published image (no server changes to test)

Fastest. From any at_client_sdk worktree:

```sh
cd ~/GitHub/at_client_sdk/<worktree>/tests/at_functional_test
./runLocal.sh            # brings up atsigncompany/virtualenv:vip, runs suite, tears down
./runLocal.sh 27000      # port-shifted (root 27000, secondaries 27001+, redis 27099)
```

Or just the environment without tests:
`docker compose -f ~/GitHub/at_server/trunk/tools/virtualenv/docker-compose.yaml up -d`

## Path B — build the atServer from branch source (testing a server PR)

This is the at_server repo's own `tests/at_functional_test/runLocal.sh` flow,
done piecemeal so you control it. **Binaries must be compiled inside a Linux
Dart container** — host-compiled Mach-O binaries make every secondary exit 127.

```sh
cd ~/GitHub/at_server/<branch-worktree>

# 1. Compile root + secondary (Linux, dart pinned to what vebase uses)
docker run --rm -v "$PWD:/app" -w /app/packages/at_root_server dart:3.11.2 \
  sh -c 'dart pub get && dart compile exe bin/main.dart -o root'
docker run --rm -v "$PWD:/app" -w /app/packages/at_secondary_server dart:3.11.2 \
  sh -c 'dart pub get && dart compile exe bin/main.dart -o secondary'

# 2. Stage binaries into the VE build context (overlay on atsigncompany/vebase)
mkdir -p tools/build_virtual_environment/ve/contents/atsign/root \
         tools/build_virtual_environment/ve/contents/atsign/secondary
cp packages/at_root_server/{root,pubspec.yaml} tools/build_virtual_environment/ve/contents/atsign/root/
cp packages/at_secondary_server/{secondary,pubspec.yaml} tools/build_virtual_environment/ve/contents/atsign/secondary/
chmod 755 tools/build_virtual_environment/ve/contents/atsign/root/root \
          tools/build_virtual_environment/ve/contents/atsign/secondary/secondary

# 3. Build + run
cd tools/build_virtual_environment/ve && docker build -t at_virtual_env:local .
docker run -d --rm --name at_server_func_cont \
  -e testingMode="true" -e httpsEnabled="true" \
  -p 6379:6379 -p 25000-25040:25000-25040 -p 64:64 -p 443:443 \
  at_virtual_env:local
```

Sanity check a branch feature made it into the binary:
`strings packages/at_secondary_server/secondary | grep -c <newVerbToken>`

### Dependency overrides for unpublished packages

If the server branch needs an unpublished at_commons/at_* version, vendor it
INSIDE the at_server repo (e.g. `.wp-ss-local/at_commons/`) and point
`packages/at_secondary_server/pubspec_overrides.yaml` (gitignored) at it with a
relative path — the compile containers mount only the repo at `/app`, so
overrides outside the repo won't resolve.

## Readiness + PKAM key install (both paths, mandatory before tests)

```sh
cd ~/GitHub/at_server/<worktree>/tests/at_functional_test
dart pub get
dart run test/check_docker_readiness.dart        # all atSigns up
dart run test/check_root_server_readiness.dart   # root TLS socket open

cd ../../tools/build_virtual_environment/install_PKAM_Keys
dart pub get && dart bin/install_PKAM_Keys.dart  # CRAM-auths every demo atsign, installs PKAM public keys
```

(The published `virtualenv:vip` image can instead use
`docker exec test-virtualenv-1 supervisorctl start pkamLoad`.)

## Demo atsigns and credentials

- All keys come from the pub.dev **at_demo_data** package (`cramKeyMap`,
  `pkamPublicKeyMap`, `pkamPrivateKeyMap`, ...) — matched inside the VE.
- PKAM-ready after install: `@alice🛠`, `@bob🛠`, `@eve🛠`, `@colin`, `@jeremy`,
  `@gateway1/2`, `@policy1/2`, etc.
- **Kept CRAM-only for onboarding tests**: `@srie`, `@sachin`, `@device2`,
  `@cloudvm2`. Use these when a test needs a *fresh* CRAM onboard
  (`AtAuth.onboard`). A fresh `docker run` of the `--rm` container makes them
  virgin again (see "Resetting the environment" — `docker restart` does NOT).
  Running `install_PKAM_Keys` does `cramAuthOnly` on these four; that bare CRAM
  auth does **not** consume onboarding virginity, so a later `AtAuth.onboard`
  still succeeds.
- at_client_sdk functional suite config: `tests/at_functional_test/config/config.yaml`
  (firstAtSign `@alice🛠`, apkam atsigns `@srie`/`@sachin`).

## Running at_client_sdk tests against the environment

```sh
cd ~/GitHub/at_client_sdk/<worktree>          # pub workspace root
dart pub get
cd tests/at_functional_test
rm -rf test/hive && rm -f test/testData/@srie.atKeys   # stale client state breaks reruns
dart test --concurrency=1 -r expanded          # full suite ~30 s against local VE
```

One-off scripts: put them in `tests/at_functional_test/tool/` and `dart run`
them — they resolve the workspace's at_client and can import
`package:at_functional_test/src/...` helpers (`FunctionalTestSyncService`,
demo credentials). Root port is env-overridable via `VIRTUALENV_BASE_PORT`.

### Pub workspace gotcha (overriding a workspace member)

`dependency_overrides` cannot override a workspace member ("Cannot override
workspace packages"). To test an unmerged at_commons (etc.) inside
at_client_sdk: comment the member out of the root `pubspec.yaml` `workspace:`
list AND add a root `pubspec_overrides.yaml` (gitignored) with a path override
to the other worktree. Both changes are local-only; revert after the branch merges.

## Resetting the environment (factory reset)

A true factory reset requires **`docker rm -f` + a fresh `docker run`** — NOT
`docker restart`.

The VE provisions the demo atSigns' CRAM secrets **once, at container
creation**. `docker restart <container>` re-runs supervisord but does NOT
re-seed that state, leaving the CRAM-only atSigns (`@srie`, `@sachin`,
`@device2`, `@cloudvm2`) in a half-state where `cramAuthenticate` fails with
`Auth failed with cramSecret <hash>` and any `AtAuth.onboard(...)` of them
throws `cram auth failed for @srie`.

```sh
# WRONG — breaks CRAM onboarding of the demo atSigns:
docker restart at_server_func_cont

# RIGHT — real factory reset (the --rm container is ephemeral, so this re-seeds):
docker rm -f at_server_func_cont
docker run -d --rm --name at_server_func_cont \
  -e testingMode="true" -e httpsEnabled="true" \
  -p 6379:6379 -p 25000-25040:25000-25040 -p 64:64 -p 443:443 \
  at_virtual_env:local
# then re-run install_PKAM_Keys before tests
```

**Symptom that flags this trap:** every functional test passes except
`enrollment_test.dart`'s "onboarding and initial enrollment using at_auth" and
"Full enrollment round trip on a freshly CRAM-onboarded atSign", which fail with
`cram auth failed for @srie`/`@sachin`. The fix is a fresh `rm -f` + `run`, not a
restart.

## Teardown

```sh
docker stop at_server_func_cont   # --rm containers remove themselves; all server state is lost
```

## Gotchas

- Container state is ephemeral (`--rm`), but only a fresh `docker run`
  factory-resets it — `docker restart` re-runs supervisord WITHOUT re-seeding
  the demo atSigns' CRAM state and breaks onboarding (see "Resetting the
  environment"). After any real reset, re-run install_PKAM_Keys; onboarded
  atsigns become virgin again.
- Emoji atsigns need quoting in shells: `'@alice🛠'`.
- `AtClientManager`/`AtClientImpl.atClientInstanceMap` are per-atSign
  singletons: to run two clients of the SAME atSign in one process (e.g. two
  APKAM enrollments), `AtClientManager.getInstance().reset()` +
  `AtClientImpl.atClientInstanceMap.clear()` between switches, with distinct
  hive/commitLog paths per identity.
- A client `put()` is local-first; force
  `FunctionalTestSyncService.getInstance().syncData(syncSvc: ...)` before
  another client is expected to see the value remotely.
