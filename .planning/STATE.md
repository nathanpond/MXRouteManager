# Project State: MXRouteManager

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-25)

**Core value:** Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.
**Current focus:** Phase 1 — App Shell & Foundation

## Current Position

Phase: 1 of 5 (App Shell & Foundation) — Plan 2 of 2 complete
Plan: 01-01 done; 01-02 done
Status: Phase 1 execution complete — awaiting phase verification
Last activity: 2026-08-25 — Completed 01-02-PLAN.md (checkpoint approved)

Progress: Phase 1: ██ 2/2 plans

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

Last session: 2026-08-25 — executed 01-02-PLAN.md (Settings scene + SettingsLink): 2 auto tasks + 1 human-verify checkpoint, all six manual demo steps confirmed by user, build verified green
Next step: Run Phase 1 verification, then proceed to Phase 2 planning
