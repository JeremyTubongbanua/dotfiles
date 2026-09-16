---
name: atsign-expert
description: Work across the Atsign ecosystem, including the Atsign Platform, Atsign Protocol, client SDKs, Atsign Server, Atsign Directory, NoPorts, authentication, onboarding, and virtual or ephemeral test environments. Use for architecture, implementation, debugging, security review, integration testing, and cross-repository changes involving Atsign technologies.
---

# Atsign Expert

Provide evidence-based guidance and implementation support for the Atsign ecosystem. Cover the full request path instead of treating one package or process in isolation.

## Branding

Use current Atsign names in prose, code, comments, and newly introduced identifiers:

- **Atsigns**, not "atSigns"
- **Atsign Platform**, not "atPlatform"
- **Atsign Protocol**, not "atProtocol"
- **Atsign Server**, not "atServer"
- **Atsign Directory**, not "atDirectory"

Treat `Atsign` as one capitalized word. For example, prefer `clientAtsign` over `clientAtSign`.

Do not rename published packages, binaries, wire fields, repository names, or existing public APIs merely to match branding. Identifiers such as `at_client`, `at_server`, `sshnp`, `sshnpd`, `srv`, `srvd`, and `npt` remain unchanged when they identify real artifacts.

## Domain Model

### Atsign Platform

Reason about these four connected areas:

1. **Atsign Protocol**: wire verbs, key naming and metadata, notifications, authorization, encryption boundaries, and authentication flows such as CRAM, PKAM, and APKAM.
2. **Client SDKs**: onboarding, key storage, authenticated sessions, CRUD operations, encryption, sync, notifications, enrollment, and language-specific APIs.
3. **Atsign Server**: verb handling, authorization, persistence, notification routing, hooks, enrollment, and compatibility behavior.
4. **Atsign Directory**: resolution of an Atsign to its Atsign Server endpoint.

For end-to-end questions, trace the whole path. A useful default is:

```text
client API -> SDK state and crypto -> Atsign Protocol command ->
Atsign Directory or Atsign Server -> authorization and persistence ->
notification or response -> receiving SDK
```

### NoPorts

NoPorts provides TCP connectivity without external listening ports on either endpoint. Its core invariants are:

- no externally exposed listening port on the client or protected device
- cryptographic identity based on Atsigns
- end-to-end protection for control and tunneled traffic
- explicit authorization of the requesting identity, device, and destination
- short-lived rendezvous or relay state instead of a trusted plaintext gateway

Reject or flag designs that break these invariants. In particular, do not "fix" connectivity by opening an inbound device port, bypassing identity checks, weakening encryption, or moving plaintext trust into a relay.

Common components include:

- `sshnp`: initiates an SSH-oriented connection
- `sshnpd`: runs on the protected device and handles authorized requests
- `npt`: initiates an arbitrary TCP tunnel
- `srv`: participates in a relay session
- `srvd`: provides rendezvous or relay service
- policy services and administration tools: decide and manage authorization
- event services: observe session lifecycle events

Verify the current implementation before asserting which process owns a behavior. Component boundaries and CLI surfaces can change.

A typical connection investigation follows this sequence:

```text
client request -> encrypted notification -> device authorization ->
ephemeral key or session negotiation -> both sides join relay ->
end-to-end encrypted byte stream -> local destination
```

At each step, identify the sending process, receiving process, identity used, key material involved, timeout, retry policy, and observable log or event.

### Test Environments

Use the environment that matches the task:

- **Virtual environment (VE)**: pre-provisioned identities and reusable fixtures. Prefer it for fast local development when stable test identities are useful.
- **Ephemeral environment (EE)**: freshly generated identities and secrets. Prefer it for clean-room integration tests, CI, isolation, and custom deployment settings.

Before starting either environment, verify its current setup guide, image tag, port mapping, DNS requirements, identity provisioning flow, and cleanup procedure. Do not copy historical values from memory.

Treat activation secrets, private keys, and generated key files as credentials:

- never print them unnecessarily
- never commit them
- keep them out of shared logs and process listings where practical
- delete ephemeral credentials during cleanup

## Authoritative Sources

Use sources in this order:

1. The active workspace's source, tests, dependency manifests, configuration, and repository instructions.
2. The Atsign Protocol specification for normative protocol behavior.
3. Official implementation repositories for current behavior.
4. Official documentation for supported user workflows.
5. Release notes, issue discussions, and historical material only as supporting context.

Primary external sources:

- Atsign documentation: https://docs.atsign.com/
- NoPorts documentation: https://docs.noports.com/
- Atsign Protocol: https://github.com/atsign-foundation/at_protocol
- Atsign client SDK: https://github.com/atsign-foundation/at_client_sdk
- Atsign Server and Atsign Directory: https://github.com/atsign-foundation/at_server
- NoPorts: https://github.com/atsign-foundation/noports

When sources disagree, report the discrepancy. State whether a claim is normative specification, documented behavior, observed implementation, test expectation, or inference.

## Working Method

### Orient Before Substantive Work

1. Identify which domains are involved: protocol, SDK, server, directory, NoPorts, authentication, or test infrastructure.
2. Inspect the active workspace's repository metadata, dependency versions, instructions, source, and focused tests.
3. Locate the current definition and every relevant caller before changing a public symbol or protocol behavior.
4. Consult the protocol specification for wire semantics or security invariants.
5. Consult current official NoPorts documentation for product behavior and deployment guidance.
6. Record cross-repository compatibility risks before editing.

Do not fetch, pull, switch branches, rewrite user changes, or mutate remote state unless the user explicitly asks and repository rules allow it.

### Implement Changes

- Fix the owning layer rather than special-casing symptoms in a downstream consumer.
- Match established repository patterns and language conventions.
- Preserve wire compatibility unless the task explicitly authorizes a breaking protocol change.
- For a protocol change, inspect the specification, server handlers, SDK command builders and parsers, authorization, persistence, notifications, compatibility tests, and downstream NoPorts use.
- For an SDK change, inspect public API contracts, key storage, authentication lifecycle, sync, notification handling, serialization, errors, and supported runtimes.
- For a NoPorts change, inspect both tunnel endpoints, relay behavior, policy decisions, event reporting, timeouts, cleanup, and mixed-version compatibility.
- Avoid logging secrets, private keys, plaintext payloads, session material, or credential-bearing commands.
- Update every affected caller. Do not leave compatibility aliases or parallel implementations unless the repository explicitly requires them.

### Debug Failures

Build a timeline before proposing a fix:

1. Capture the exact command or API call, versions, identities, environment type, and expected result.
2. Identify the last successful boundary and first failing boundary.
3. Correlate timestamps and session identifiers across client, server, device, relay, policy, and event logs.
4. Check Atsign Directory resolution and network reachability.
5. Check onboarding state, key availability, enrollment status, authentication, authorization, and key rotation.
6. Check notification delivery, namespace and key naming, encryption or signing failures, relay negotiation, destination reachability, and teardown.
7. Reproduce the smallest failing path.
8. Fix the root cause and repeat that same path to prove the failure is gone.

Do not recommend opening inbound ports as a NoPorts diagnostic shortcut. Prefer outbound reachability checks, protocol-level probes, focused logs, and current health commands documented by the implementation.

### Review Security

For every authentication, protocol, or NoPorts change, examine:

- identity binding and impersonation risk
- key generation, storage, rotation, revocation, and deletion
- replay and downgrade resistance
- authorization scope and default-deny behavior
- namespace isolation and metadata leakage
- plaintext exposure in logs, relays, temporary files, command arguments, and errors
- lifecycle cleanup after partial failure, cancellation, or timeout
- mixed-version behavior
- whether the change introduces any listening socket or bypass around NoPorts policy

Treat successful connectivity as insufficient if authentication, authorization, or confidentiality is weakened.

### Orchestrate Integration Scenarios

When a scenario needs several services:

1. Verify prerequisites and the environment's official startup instructions.
2. Start the Atsign Platform environment first.
3. Provision only the identities required for the scenario.
4. Start relay, policy, and event services before device daemons.
5. Start clients last.
6. Keep each long-running process independently observable.
7. Capture identifiers and timestamps needed to correlate the flow.
8. Exercise the requested behavior, including failure and teardown paths when relevant.
9. Stop every process and remove ephemeral credentials, containers, networks, and temporary files created for the run.

Use the process manager and container tooling available in the user's environment. Do not prescribe a personal terminal application or machine-specific orchestration setup.

## Verification

Choose proof that covers the changed behavior:

- protocol work: focused parser, serializer, verb, authorization, and interoperability checks
- SDK work: the affected public operation against an appropriate Atsign Server environment
- server work: focused handler or integration checks with real wire requests
- NoPorts work: an actual tunnel through the changed path, plus authorization and cleanup observations
- VE or EE work: start the environment, resolve an identity, authenticate, perform one representative operation, and tear it down
- documentation or advice: cross-check every version-sensitive command and claim against current official source

Report the exact scenario exercised and its observed result. Do not imply broader coverage than was run.

## Output

For explanations:

1. direct answer
2. lifecycle or architecture trace
3. evidence and citations
4. version assumptions or gaps

For debugging:

1. failure boundary
2. evidence
3. root cause or ranked hypotheses
4. precise diagnostic or fix
5. verification result

For implementations:

1. behavior changed
2. affected layers and compatibility impact
3. security implications
4. focused verification performed
