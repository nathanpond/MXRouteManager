---
phase: 03-mxroute-api-client
plan: "02"
subsystem: api-client
tags: [urlsession, async-await, urlprotocol-mock, swift-testing]
requires: [03-01]
provides: [MXRouteClient core, listDomains, MockURLProtocol harness]
affects: [03-03, 03-04, phase-4-ui]
tech-stack:
  added: []
  patterns: [injectable session/baseURL instead of #if DEBUG hooks, single send() pipeline mapping status+envelope to one MXRouteError, session-scoped URLProtocol mocking with httpBodyStream draining, credentials-as-value-snapshot instead of a stored provider closure]
key-files:
  created: [MXRouteManager/Services/MXRouteClient.swift, MXRouteManagerTests/MockURLProtocol.swift, MXRouteManagerTests/MXRouteClientTests.swift]
  modified: []
decisions:
  - "MXRouteCredentials is a plain trimmed/validated value struct built at MXRouteClient.live() construction time, not a stored `() throws -> MXRouteCredentials` closure over AppSettings — keeps the client Sendable and free of actor-isolation coupling"
  - "send() checks HTTP status before attempting envelope decode, so a non-JSON 5xx (e.g. an HTML error page) maps to .api(code: HTTP_5xx, ...) rather than .decoding — decode failures on a 2xx status are the only path to .decoding"
  - "401 always maps to .unauthorized, even when the body decodes with a different code — CONF-04 needs to distinguish bad credentials from every other API error"
  - "MockURLProtocol.handler is nonisolated(unsafe) static state; tests run in a @Suite(.serialized) struct with defer { handler = nil } per test to avoid races, since Swift Testing may otherwise run tests concurrently"
metrics:
  duration: "~35 min"
  completed: "2026-08-26"
---

# Phase 3 Plan 02: MXRouteClient Core Summary

Built `MXRouteClient` end to end: `MXRouteCredentials` (failable, trimming init), an injectable `session`/`baseURL` client, a single `send()` pipeline that maps every HTTP status/envelope/transport-failure combination to one `MXRouteError` case, `listDomains()`, and a `@MainActor live(settings:keychain:session:)` factory that reads `AppSettings` + `KeychainService` once at construction. Backed by a reusable `MockURLProtocol` harness (session-scoped, `httpBodyStream`-draining `capturedBody`) and 11 new Swift Testing cases covering auth headers, decoding, and five distinct error mappings. Suite is now 29/29 green (18 prior + 11 new), matching the plan's expected count exactly.

## What Was Built

- **Task 1** (`cedd1e4`): `MXRouteManager/Services/MXRouteClient.swift` — `MXRouteCredentials`, `MXRouteClient` (injectable `session: URLSession = .shared`, `baseURL: URL = productionBaseURL`), private `makeRequest`/`send`, `static func failure(status:body:)`, `listDomains()`, and a `@MainActor` `live(settings:keychain:session:)` factory. No logging, no other endpoints, no `#if DEBUG`.
- **Task 2** (`c3151e7`): `MXRouteManagerTests/MockURLProtocol.swift` — session-scoped `URLProtocol` stub with a `nonisolated(unsafe)` static handler, `makeMockSession()`, `makeResponse(_:url:)`, `mockBaseURL`, and `URLRequest.capturedBody` (drains `httpBodyStream` with a 4096-byte buffer when `httpBody` is nil).
- **Task 3** (`793bd8f`): `MXRouteManagerTests/MXRouteClientTests.swift` — 11 `@Test` cases in a `@Suite(.serialized)` struct: auth headers + URL, successful decode (including empty array), and error mappings for 401-with-body, 401-without-body, API error envelope (400), non-JSON 500, unreadable 200 JSON, transport failure, missing credentials (asserting no request was made), plus `MXRouteCredentials` blank/whitespace validation.

## Deviations from Plan

None. All three tasks matched the plan's specified shapes exactly; every `<verify>` command and `<done>` criterion passed on the first attempt with no bugs found.

## Verification

- `xcodebuild build` (Task 1): `** BUILD SUCCEEDED **`.
- `xcodebuild build-for-testing` (Task 2): `** TEST BUILD SUCCEEDED **`.
- `xcodebuild test -only-testing:MXRouteManagerTests`: `** TEST SUCCEEDED **`, all 29 tests passed (11 new `MXRouteClientTests` + 18 prior).
- Plan-level `<verification>`: `URLSession` appears only in `MXRouteClient.swift`; no `api.mxroute.com` in the test target; `project.pbxproj` diff is empty; no `print(`/`NSLog` in the client.
- Applied the wave-1 environment lessons throughout: `pkill -x MXRouteManager` before every `xcodebuild test` invocation, xcodebuild run in the foreground with generous timeouts, `KeychainService.hasKey` left untouched (attributes-only).

## Next Plan Readiness

Plan 03-03 can extend `MXRouteClient` with `listEmailAccounts` and `createForwarder` directly on top of the existing `send()` pipeline (inherits auth, encoding, and error mapping for free) and reuse `MockURLProtocol`/`makeMockSession()`/`capturedBody` unchanged for POST body assertions. Plan 03-04 can call `MXRouteClient.live(settings:)` from Settings for CONF-04 (Test Connection) — the first live call will trigger one Keychain permission prompt on this binary signature, as noted in 03-01's summary.
