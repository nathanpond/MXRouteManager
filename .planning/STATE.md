# Project State: MXRouteManager

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-25)

**Core value:** Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.
**Current focus:** Phase 5 — Polish & Release (executing)

## Current Position

Phase: 5 of 5, Plans 1-2 of 3 complete (first-run/empty states + app icon, parallel wave)
Plan: 05-03 next
Status: Phase 5 in progress
Last activity: 2026-08-26 — Wave 1 complete (05-01, 05-02 in parallel, no conflicts)

Progress: Phases: ████░ 4/5 complete
Phase 5: ██░ 2/3 plans

## Accumulated Context

### Decisions

- Create-only MVP; forwarder list/delete deferred to v2
- Destination picker limited to accounts on the selected domain (one API call)
- API key in Keychain via KeychainService; X-Server/X-Username in @AppStorage
- macOS 15 Sequoia minimum; SwiftUI + Foundation only, no third-party dependencies
- Test Connection (CONF-04) lives in Phase 3 since it needs the API client
- Non-source placeholder files (e.g. `.gitkeep`) inside a synchronized group that land in an app-target folder must be excluded via a `PBXFileSystemSynchronizedBuildFileExceptionSet` (scoped `exceptions` on the `PBXFileSystemSynchronizedRootGroup`) — Xcode's synchronized groups do NOT skip dot-files on this project/Xcode version, and multiple `.gitkeep` files at different paths collide on the same bundle-relative Resources destination without this exception set
- `@Observable` + `@AppStorage` coexist via `@ObservationIgnored @AppStorage` on the private stored property plus manual `access(keyPath:)`/`withMutation(keyPath:)` in a computed public property — this primary pattern compiled cleanly (no fallback to plain stored properties + `didSet` needed)
- `hasAPIKey` on `AppSettings` is a stored `Bool` mutated explicitly by `saveAPIKey`/`removeAPIKey`, not a computed pass-through to `KeychainService.hasKey` — keeps SwiftUI observation working and avoids a Keychain hit on every render
- Keychain PRESENCE checks must be attributes-only (`kSecReturnAttributes`, never `kSecReturnData`) — reading secret data triggers the ACL prompt, and any signature/entitlement change re-invalidates prior approval, hanging app launch and the unit-test runner handshake. Secret reads happen only at point of use; first live API call per binary shows one prompt (user picks Always Allow)
- Before running `xcodebuild test`, kill any running MXRouteManager.app instance (checkpoint leftovers block the test-host launch: "test runner hung before establishing connection")
- MXRouteClient credentials are a plain trimmed/validated value snapshot (`MXRouteCredentials`), not a stored provider closure over `AppSettings` — keeps the client `Sendable` and free of actor-isolation coupling; injectable `session`/`baseURL` (no `#if DEBUG` hooks) let tests mock the network via a session-scoped `URLProtocol`
- `send()` checks HTTP status before attempting envelope decode, so a non-JSON 5xx maps to `.api(code: HTTP_5xx, ...)` rather than `.decoding`; 401 always maps to `.unauthorized` even when the body decodes with a different code
- `listEmailAccounts(domain:)` sorts by email in the client (not the view); `createForwarder(domain:alias:destinations:)` synthesizes a local `Forwarder` when the API's documented bodiless 201 makes `send()` return `nil`, so a successful create is never reported as a decoding failure
- Swift Testing's `@Suite(.serialized)` only serializes tests *within* one suite — two suites sharing `MockURLProtocol.handler` (a `nonisolated(unsafe) static`) can still run concurrently and clobber each other's mock responses. Fixed with an actor-backed `MockNetworkLock`/`withMockNetwork { }` helper in `MockURLProtocol.swift`; every test that sets the handler, in every suite, must wrap its body in `withMockNetwork { }`

### Blockers

(None)

### Open Issues

Issue count: 0 (see .planning/issues/open/)

## Session Continuity

Last session: 2026-08-26 — Phase 5 wave 1 executed (05-01 first-run/empty states, 05-02 app icon — parallel)
Next step: Execute plan 05-03 (README, Release build, final checkpoint)