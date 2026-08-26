---
phase: 03-mxroute-api-client
plan: "01"
subsystem: api-client
tags: [entitlements, sandbox, codable, mxroute-api, swift-testing, keychain]
requires: [02-01, 02-02]
provides: [network-client entitlement, API models, typed MXRouteError, prompt-free hasKey]
affects: [03-02, 03-03, 03-04]
tech-stack:
  added: []
  patterns: [ENABLE_OUTGOING_NETWORK_CONNECTIONS build setting for sandbox entitlements, attributes-only Keychain presence checks]
key-files:
  created: [MXRouteManager/Models/MXRouteModels.swift, MXRouteManagerTests/MXRouteModelsTests.swift]
  modified: [MXRouteManager.xcodeproj/project.pbxproj, MXRouteManager/Services/KeychainService.swift]
decisions:
  - "Network entitlement via ENABLE_OUTGOING_NETWORK_CONNECTIONS build setting (two lines, both app-target configs) — verified from the signed binary's entitlements, no .entitlements file needed"
  - "KeychainService.hasKey must be an attributes-only SecItemCopyMatching — reading secret data at launch triggers the ACL prompt whenever the binary's signature/entitlements change, which hangs the app and the test runner"
metrics:
  duration: "~45 min including debugging a test-runner hang"
  completed: "2026-08-26"
---

# Phase 3 Plan 01: Network Entitlement & API Models Summary

Sandboxed outgoing-network entitlement granted via two `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` build-setting lines (verified with `codesign -d --entitlements` on the built product: `com.apple.security.network.client => true` alongside app-sandbox), plus Codable MXRoute API surface: `APIEnvelope<T>`, `APIErrorBody`, `EmailAccount`, `Forwarder`, and a typed `MXRouteError` — covered by 9 new decoding tests (suite now 18/18 green).

## What Was Built

- **Task 1** (`a7ddc2b`): `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` added to both app-target configurations; entitlement confirmed in the signed Debug binary.
- **Task 2** (`16a8f9c`): `MXRouteManager/Models/MXRouteModels.swift` — envelope/error types, `EmailAccount`, `Forwarder`, `MXRouteError` (Equatable, carries API code/message/field).
- **Task 3** (`55ee067`): `MXRouteManagerTests/MXRouteModelsTests.swift` — 9 Swift Testing cases for envelope success/error decoding, model field mapping, and error extraction.

## Deviations from Plan

**1. [Rule 1 - Bug] Test runner hang caused by launch-time Keychain secret read** (`498f542`)

- **Found during:** Task 3 verification — `xcodebuild test` failed repeatedly with "The test runner hung before establishing connection."
- **Root cause (bisected):** the entitlement change altered the app binary's code signature, invalidating the keychain item ACL approval granted at the Phase 2 checkpoint. `AppSettings.init` calls `KeychainService.hasKey`, which was implemented as `load()` — a `kSecValueData` read that now blocked on a keychain permission prompt at launch, hanging the test-host handshake. Reverting the entitlement made tests pass; restoring it with the fix below also passes.
- **Fix:** `hasKey` is now an attributes-only `SecItemCopyMatching` (no `kSecValueData`), which never triggers the ACL prompt. Actual secret reads (`load()`) happen only when a request needs the key — the user will see one keychain prompt on first real API use per binary, which is expected and can be "Always Allow"-ed.
- **Also cleaned up:** a stale app instance from the Phase 2 checkpoint was still running and blocking the test host launch; killed.

## Next Plan Readiness

03-02 builds `MXRouteClient` on these types. Note for 03-04's checkpoint: the first live API call will trigger one keychain permission prompt (new binary signature) — the user should click "Always Allow".
