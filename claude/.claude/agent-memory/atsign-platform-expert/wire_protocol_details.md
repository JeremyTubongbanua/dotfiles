---
name: wire_protocol_details
description: Exact wire-protocol framing verified from source (root lookup, secondary connect, verb framing, response terminator, TLS setup) across at_client_sdk, at_server, at_java
type: reference
---

Verified 2026-07-10 against at_client_sdk/trunk, at_server/trunk, and at_java/at_client (Java) by direct grep/Read (not docs). Re-verify file:line if repos have moved on since this date — these are living codebases.

## A. Root server lookup (client -> root.atsign.org:64)
- `at_client_sdk/trunk/packages/at_lookup/lib/src/cache/cacheable_secondary_address_finder.dart` class `SecondaryUrlFinder._findSecondary` (~line 184-212).
- Atsign is stripped of leading `@` before sending (line ~189: `if (atsign.startsWith('@')) atsign = atsign.replaceFirst('@', '');`).
- Client waits for root's initial `@` prompt (`answer.endsWith('@')`), then writes `'$atsign\n'` — i.e. `"alice\n"`, NOT `"@alice\n"`. No `@` prefix on the wire to root.

## B. Root server response format
- Success: `"host:port\r\n@"` (contains `:`). Client checks `answer.contains(':')`.
- Not found: `"null\r\n@"`. Client checks `answer.startsWith('null')` -> throws `SecondaryNotFoundException`.
- Server side: `at_server/trunk/packages/at_root_server/lib/src/client/at_root_client.dart:66-67` — `result ??= 'null'; write('$result\r\n@');`

## C. Unsolicited `@` banner on connect
Both root and secondary servers push a bare `@` immediately on socket accept, before any client verb:
- Root: `at_root_server_impl.dart:93` — `client.write('@');`
- Secondary (raw TLS): `at_secondary_server/lib/src/server/at_secondary_impl.dart:667` — `await connection.write('@');`
- Secondary (WebSocket path): same file `:614`.
No dedicated "skip banner" code client-side — it's absorbed into the same terminator/prompt state machine used for regular responses.

## D. Verb command framing (client -> secondary)
- `at_lookup/lib/src/connection/at_lookup_impl.dart` `_sendCommand` (~line 665-668) just does `await _connection!.write(command)` — no `\n` appended by the transport layer itself.
- Callers are responsible for the trailing `\n`, e.g. `'pkam:$signature\n'` (~line 459), `'cram:$digest\n'` (~line 545).
- No `info` verb builder exists client-side in at_client_sdk (info is essentially server/ops-only, invoked ad hoc).

## E. Response terminator (server -> client)
- `at_server/trunk/packages/at_secondary_server/lib/src/verb/handler/response/base_response_handler.dart` builds a `prompt` string: `isAuthenticated ? '$atSign@' : (isPolAuthenticated ? '$fromAtSign@' : '@')` (~line 28-39).
- Success format (`default_response_handler.dart:8`): `'$verbResult\n$prompt'` -> e.g. `"data:...\n@"` or authenticated `"data:...\n@alice@"`.
- Error format (`base_response_handler.dart:35`): `'error:${response.errorCode}:${response.errorMessage}\n$prompt'`.
- Client read loop: `at_lookup/lib/src/connection/outbound_message_listener.dart` `messageHandler` (~line 84-102) — completion signal is a byte `@` (0x40) immediately preceded by `\n` (0x0A) in the buffer. Strips trailing `\n`, then `_stripPrompt` (~line 119-128) removes the `@...@` prompt wrapper. `_isValidResponse` (~line 176-181) also accepts bare `@...@` (auth handshake) or `data:`/`stream:`/`error:` prefixed payloads.
- No standalone `Constants` class holds `'@'` as a named literal — it's an inline literal in both `at_secondary_impl.dart` and `base_response_handler.dart`.

## F. TLS setup in at_client_sdk
- `at_lookup/lib/src/util/secure_socket_util.dart` `SecureSocketUtil.createSecureSocket` (~line 9-51): uses `SecurityContext.defaultContext`, optional `setTrustedCertificates`, then `SecureSocket.connect(host, port, context: securityContext)`, then `setOption(SocketOption.tcpNoDelay, true)`.
- No `onBadCertificate` override, no SNI override, no `supportedProtocols` found anywhere in at_client_sdk — relies on Dart's default cert validation behavior. (Notable: this means cert pinning/bypass, if it exists, is not here — worth re-checking if a future task involves TLS trust issues.)

## Info verb handler (server)
- `at_secondary_server/lib/src/verb/handler/info_verb_handler.dart:24-25` — `accept(String command) => command == 'info' || command.startsWith('info:');`
- Response: `response.data = json.encode(infoMap)`, wrapped by `DefaultResponseHandler` into `data:{...}\n@`.

## Java client (at_java/at_client) differences from Dart
- `AtConnectionBase.java:145-147` explicitly appends `\n` if the caller's command doesn't already end with one — opposite of Dart's approach (Dart pushes `\n` responsibility to verb-builder callers, transport layer doesn't touch it).
- Reads via `Scanner.nextLine()` (~line 165) — relies on plain `\n`-delimited lines rather than replicating the `@`-terminator state machine that Dart's `OutboundMessageListener` uses.
- `AtRootConnection.parseRawResponse` (`AtRootConnection.java:30-36`) strips only a leading `@`; a raw `"null"` response is not treated as an error at parse time — `AtSecondaryNotFoundException` is thrown by the caller of `findSecondary` based on that string, not inside the parser.

## Key files to re-check if code has moved
- at_client_sdk/trunk/packages/at_lookup/lib/src/cache/cacheable_secondary_address_finder.dart
- at_client_sdk/trunk/packages/at_lookup/lib/src/connection/at_lookup_impl.dart
- at_client_sdk/trunk/packages/at_lookup/lib/src/connection/outbound_message_listener.dart
- at_client_sdk/trunk/packages/at_lookup/lib/src/util/secure_socket_util.dart
- at_server/trunk/packages/at_root_server/lib/src/client/at_root_client.dart
- at_server/trunk/packages/at_root_server/lib/src/server/at_root_server_impl.dart (banner write)
- at_server/trunk/packages/at_secondary_server/lib/src/server/at_secondary_impl.dart
- at_server/trunk/packages/at_secondary_server/lib/src/verb/handler/response/base_response_handler.dart and default_response_handler.dart
- at_server/trunk/packages/at_secondary_server/lib/src/verb/handler/info_verb_handler.dart
- at_java/at_client/.../AtConnectionBase.java, AtRootConnection.java
