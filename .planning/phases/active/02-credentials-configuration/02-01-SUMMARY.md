---
phase: 02-credentials-configuration
plan: "01"
subsystem: credentials
tags: [keychain, security-framework, swift-testing]
requires: [01-01, 01-02]
provides: [KeychainService save/load/delete API]
affects: [02-02, 02-03, phase-3-api-client]
tech-stack:
  added: []
  patterns: [SecItem generic password update-then-add, isolated test service names]
key-files:
  created: [MXRouteManager/Services/KeychainService.swift, MXRouteManagerTests/KeychainServiceTests.swift]
  modified: []
decisions:
  - "save() uses SecItemUpdate-then-SecItemAdd (not delete-then-add) so a failed add can never destroy an existing key"
  - "Default file-based login keychain only — no kSecUseDataProtectionKeychain, no kSecAttrAccessible/access groups/kSecAttrSynchronizable, no entitlements file — keeps the item visible in Keychain Access.app for the phase demo"
  - "service/account are injectable init params defaulting to \"MXRouteManager\"/\"api-key\"; tests use a fully isolated \"MXRouteManager.tests\"/\"test-api-key\" pair so they can never touch the real key"
metrics:
  duration: "~10 minutes"
  completed: "2026-08-26"
---

Built `KeychainService`, the sole component that touches the API key at rest: `save`/`load`/`delete` over `SecItemAdd`/`SecItemUpdate`/`SecItemCopyMatching`/`SecItemDelete` for a generic-password Keychain item, with `load()` returning `nil` (not throwing) when absent and `delete()` idempotent on a missing item. Four Swift Testing tests (`@Suite(.serialized)`) prove save-then-load, overwrite-via-update, nil-when-absent, and idempotent-delete, all running against an isolated `"MXRouteManager.tests"` service name with `defer`-based cleanup — never touching the real `"MXRouteManager"`/`"api-key"` item.

Deviations: None — plan executed exactly as written.

Verification: Debug app build succeeded; scoped `-only-testing:MXRouteManagerTests` run reported `** TEST SUCCEEDED **` with all four Keychain tests plus the pre-existing template test passing; `project.pbxproj` untouched (fileSystemSynchronizedGroups picked up both new files automatically); no `UserDefaults`/`AppStorage`/`print`/`NSLog` in `KeychainService.swift`; no leftover `MXRouteManager.tests` Keychain item after the test run.

Next-plan readiness: `KeychainService.shared` (service: `"MXRouteManager"`, account: `"api-key"`) is ready for plan 02-02 to wire into `AppSettings`; no callers exist yet outside the tests, as required.
