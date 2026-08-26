---
phase: 03-mxroute-api-client
plan: "03"
subsystem: api-client
tags: [endpoints, forwarders, email-accounts, swift-testing]
requires: [03-02]
provides: [listEmailAccounts, createForwarder]
affects: [03-04, phase-4-ui]
tech-stack:
  added: []
  patterns: [actor-backed async lock (MockNetworkLock/withMockNetwork) to serialize Swift Testing suites sharing a nonisolated(unsafe) static mock handler across suite boundaries]
key-files:
  created: [MXRouteManagerTests/MXRouteEndpointTests.swift]
  modified: [MXRouteManager/Services/MXRouteClient.swift, MXRouteManagerTests/MockURLProtocol.swift, MXRouteManagerTests/MXRouteClientTests.swift]
decisions:
  - "listEmailAccounts(domain:) sorts results by email (localizedCaseInsensitiveCompare) in the client, not the view — Phase 4's destination picker renders the array directly and DirectAdmin returns mailboxes in creation order"
  - "createForwarder(domain:alias:destinations:) falls back to a locally-synthesized Forwarder (alias, alias@domain, trimmed destinations) when send() returns nil for the API's documented bodiless 201 — a bodiless success must never be reported as a decoding failure"
  - "Local validation (blank domain/alias/destinations) throws .invalidRequest before any request is built, but does not replicate server-side alias-format rules — those stay server- and Phase-4-owned"
  - "Cross-suite Swift Testing race fix: added MockNetworkLock (an actor) and a withMockNetwork { } helper to MockURLProtocol.swift; every @Test in both MXRouteClientTests and MXRouteEndpointTests wraps its body in withMockNetwork so only one test across BOTH suites touches the shared nonisolated(unsafe) static handler at a time — @Suite(.serialized) alone only serializes within a single suite and does not prevent two suites from interleaving"
metrics:
  duration: "~50 min"
  completed: "2026-08-26"
---

# Phase 3 Plan 03: Endpoints (listEmailAccounts + createForwarder) Summary

Added the two remaining `MXRouteClient` endpoints on top of the plan-03-02 `send()` pipeline: `listEmailAccounts(domain:)` (GET, sorted by address) and `createForwarder(domain:alias:destinations:)` (POST, with the documented-empty-201 local-`Forwarder` fallback). Backed both with a new 12-case Swift Testing suite covering the domain-scoped path, sorted decoding, hostile-domain path-segment encoding, `NOT_FOUND`/`CONFLICT`/`VALIDATION_ERROR` mappings, the empty-body fallback, and POST body assertions (via `capturedBody` + `JSONSerialization`, never raw-string comparison). Suite is now 41/41 green (29 prior + 12 new), matching the plan's expected count exactly.

## What Was Built

- **Task 1** (`fa9bf51`): `listEmailAccounts(domain:)` on `MXRouteClient` — rejects a blank domain with `.invalidRequest` before any request, calls `send([EmailAccount].self, ...)` against `domains/{domain}/email-accounts`, sorts the result by email.
- **Task 2** (`7d1197d`): `createForwarder(domain:alias:destinations:)` on `MXRouteClient` plus a file-scope `CreateForwarderBody: Encodable` — trims/validates domain, alias, and destinations locally; POSTs `{alias, destinations}` to `domains/{domain}/forwarders`; returns the decoded `Forwarder` or, when `send()` returns `nil` for the bodiless `201`, a locally-built one.
- **Task 3** (`442f67a`): `MXRouteManagerTests/MXRouteEndpointTests.swift` — 12 `@Test` cases in a `@Suite(.serialized)` struct exercising both new endpoints end to end against `MockURLProtocol`.

## Deviations from Plan

One deviation, auto-fixed and documented per the no-checkpoint protocol:

**Cross-suite test race.** Adding `MXRouteEndpointTests` as a second suite that also drives `MockURLProtocol` surfaced a pre-existing hazard: `MockURLProtocol.handler` is a single `nonisolated(unsafe) static`, and `@Suite(.serialized)` only serializes tests *within* one suite — it does not stop Swift Testing from running two different suites concurrently. With two suites both setting/reading the shared handler, tests intermittently observed each other's mock responses (confirmed empirically: `MXRouteClientTests` alone was 100% green, `MXRouteEndpointTests` alone was 100% green, but running both together failed a different, nondeterministic subset of tests each time — the signature of a race, not a logic bug).

Fix: added an actor-backed `MockNetworkLock` and a `withMockNetwork { }` helper to the shared harness (`MXRouteManagerTests/MockURLProtocol.swift`), then wrapped every handler-setting `@Test` body in **both** `MXRouteEndpointTests.swift` (this plan) and `MXRouteClientTests.swift` (plan 03-02's file) in `try await withMockNetwork { ... }`. This required touching a file outside this plan's declared `files_modified` — a mechanical wrap only, with no assertion or behavioral changes to any existing test. Verified fixed across two consecutive full-suite runs (both `** TEST SUCCEEDED **`, 41/41).

No other deviations. All other task shapes, validations, and error mappings matched the plan exactly.

## Verification

- Task 1 verify: `listEmailAccounts` present inside the struct, no stray `URLRequest(` outside `makeRequest`, `** BUILD SUCCEEDED **`.
- Task 2 verify: `createForwarder` present, `CreateForwarderBody`/`@discardableResult` present, no `print`/`NSLog`, `** BUILD SUCCEEDED **`.
- Task 3 verify: `** TEST SUCCEEDED **`, 12 `@Test` in the new file, no `URLSession.shared`/`KeychainService.shared`/`UserDefaults.standard`/`api.mxroute.com` in the test target (the one `URLSession.shared` grep hit is a doc comment in `MockURLProtocol.swift`, not usage).
- Plan-level `<verification>`: full suite `** TEST SUCCEEDED **` with **41 tests passing** (29 prior + 12 new); `listDomains`/`listEmailAccounts`/`createForwarder` all present on `MXRouteClient`; `URLSession` appears only in `MXRouteClient.swift`; `project.pbxproj` diff empty; no `print(`/`NSLog` in `Services/`.
- Ran the full suite twice in a row post-fix to confirm the race was actually closed, not just avoided by luck.

## Next Plan Readiness

Plan 03-04 (Test Connection + checkpoint) can call `MXRouteClient.live(settings:)` directly — `listDomains`, `listEmailAccounts`, and `createForwarder` are all in place on top of one shared, tested `send()` pipeline. Phase 4's destination picker can call `listEmailAccounts(domain:)` for pre-sorted mailbox data, and forwarder creation (`createForwarder`) is feature-complete for the create-only MVP scope. Test authors touching `MockURLProtocol` in future plans should route through `withMockNetwork { }` rather than setting `MockURLProtocol.handler` directly, to avoid reintroducing the cross-suite race.
