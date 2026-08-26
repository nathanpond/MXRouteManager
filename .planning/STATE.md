# Project State: MXRouteManager

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-25)

**Core value:** Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.
**Current focus:** Phase 3 — MXRoute API Client

## Current Position

Phase: 3 of 5, Plan 1 of 4 complete (network entitlement + API models)
Plan: 03-01 complete
Status: Phase 3 in progress
Last activity: 2026-08-26 — Plan 03-01 executed; test-runner hang root-caused and fixed (hasKey ACL prompt)

Progress: Phases: ██░░░ 2/5 complete
Phase 3: █░░░ 1/4 plans

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

### Blockers

(None)

### Open Issues

Issue count: 0 (see .planning/issues/open/)

## Session Continuity

Last session: 2026-08-26 — Phase 2 executed and verified (3 plans, human checkpoint approved, verifier passed 12/12)
Next step: `/kata-plan-phase 3`
