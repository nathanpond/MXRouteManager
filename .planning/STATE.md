# Project State: MXRouteManager

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-25)

**Core value:** Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.
**Current focus:** Phase 2 — Credentials & Configuration (not yet planned)

## Current Position

Phase: 1 of 5 complete (App Shell & Foundation) — verified 8/8 must-haves, moved to completed/
Plan: —
Status: Ready for `/kata-plan-phase 2`
Last activity: 2026-08-25 — Phase 1 verified (passed) and completed; GitHub issues #1/#6/#7 closed

Progress: Phases: █░░░░ 1/5 complete

## Accumulated Context

### Decisions

- Create-only MVP; forwarder list/delete deferred to v2
- Destination picker limited to accounts on the selected domain (one API call)
- API key in Keychain via KeychainService; X-Server/X-Username in @AppStorage
- macOS 15 Sequoia minimum; SwiftUI + Foundation only, no third-party dependencies
- Test Connection (CONF-04) lives in Phase 3 since it needs the API client
- Non-source placeholder files (e.g. `.gitkeep`) inside a synchronized group that land in an app-target folder must be excluded via a `PBXFileSystemSynchronizedBuildFileExceptionSet` (scoped `exceptions` on the `PBXFileSystemSynchronizedRootGroup`) — Xcode's synchronized groups do NOT skip dot-files on this project/Xcode version, and multiple `.gitkeep` files at different paths collide on the same bundle-relative Resources destination without this exception set

### Blockers

(None)

### Open Issues

Issue count: 0 (see .planning/issues/open/)

## Session Continuity

Last session: 2026-08-25 — Phase 1 executed and verified (2 plans, human checkpoint approved, verifier passed 8/8)
Next step: `/kata-plan-phase 2`
