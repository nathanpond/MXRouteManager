---
phase: 02-credentials-configuration
verified: 2026-08-26T11:56:00Z
status: passed
score: 12/12 must-haves verified (aggregate across plans 02-01/02-02/02-03)
---

# Phase 2: Credentials & Configuration Verification Report

**Goal:** The user can configure and persist all three MXRoute credentials, with the API key held only in the Keychain.

**Status: PASSED**

## Observable Truths

| Truth | Evidence | Status |
|---|---|---|
| API key round-trips (save/load/overwrite/delete) via Security framework only | `KeychainService.swift` uses only `Foundation`/`Security`; `save` does update-then-add (`SecItemUpdate` → `SecItemAdd` on `errSecItemNotFound`); `delete` treats `errSecSuccess`/`errSecItemNotFound` as success | Exists, substantive, wired |
| `load()` returns nil when absent, not throw | `if status == errSecItemNotFound { return nil }` before the generic error guard | Exists, substantive, wired |
| No third-party dependency | `import Foundation` / `import Security` only in KeychainService.swift | Verified |
| Server/username persist via `@AppStorage`, exposed by observable model with `isConfigured` | `AppSettings` is `@Observable final class`; `@ObservationIgnored @AppStorage` pair with manual `access`/`withMutation`; `isConfigured` combines trimmed server/username + `hasAPIKey` | Exists, substantive, wired |
| `hasAPIKey` flips immediately without relaunch | Stored property mutated directly in `saveAPIKey`/`removeAPIKey` (not computed from Keychain), so `@Observable` tracks it | Exists, substantive, wired |
| Settings UI: SecureField + server/username fields, key written on commit | `SettingsView.swift`: `TextField` bound to `$settings.serverHostname`/`$settings.username`; `SecureField` bound to local `@State apiKeyInput`; `saveKey()` calls `settings.saveAPIKey(key)` then clears the field | Exists, substantive, wired |
| API key never in UserDefaults or on disk (outside Keychain) | `grep -rn "UserDefaults\|AppStorage" MXRouteManager/` → only `AppSettings.swift`; no stored `apiKey` property anywhere; SecureField never pre-filled | Verified |
| Item lands in login (file-based) keychain, not data-protection keychain | Non-invasive `security find-generic-password -s "MXRouteManager" -a "api-key"` (no `-w`) returned the item from `login.keychain-db` with `svce="MXRouteManager"`, `acct="api-key"` | Verified |

## Required Artifacts

| Artifact | Present | Notes |
|---|---|---|
| `MXRouteManager/Services/KeychainService.swift` | Yes | save/load/delete/hasKey over SecItem*, update-then-add save |
| `MXRouteManagerTests/KeychainServiceTests.swift` | Yes | 4 tests, isolated service name `MXRouteManager.tests`, `@Suite(.serialized)`, no use of `.shared` |
| `MXRouteManager/Models/AppSettings.swift` | Yes | `@Observable`, no stored `apiKey` property |
| `MXRouteManagerTests/AppSettingsTests.swift` | Yes | 4 tests, isolated `UserDefaults` suite + isolated keychain service name |
| `MXRouteManager/Views/SettingsView.swift` | Yes | Real Connection + API Key sections replacing Phase 1 placeholder |

## Key Link Verification

| Link | Verified |
|---|---|
| KeychainService service/account fixed constants with injectable overrides; tests use separate names | Yes — `"MXRouteManager.tests"` / `"MXRouteManager.tests.settings"` in tests |
| `kSecUseDataProtectionKeychain` NOT set | Confirmed via grep and live Keychain lookup returning the item from `login.keychain-db` |
| `save()` is update-then-add, not delete-then-add | Confirmed in source; `savingTwiceOverwrites` test passed |
| `AppSettings` owns `KeychainService`, mutates own `hasAPIKey` in save/remove | Confirmed in source |
| One `AppSettings` instance injected via `.environment(settings)` on both scenes | Confirmed in `MXRouteManagerApp.swift` |
| `init(store:keychain:)` injects isolated dependencies for tests | Confirmed; tests never touch `.standard`/`.shared` |
| Save clears local `@State` field after commit; SecureField never pre-filled | Confirmed: `apiKeyInput = ""` after `saveAPIKey`; no `load()` call in the view |

## Requirements Coverage

- **CONF-01** (Keychain via KeychainService): Satisfied — save/load/delete/overwrite via `SecItem*`, no third-party dependency, proven by 4 passing unit tests plus a live, non-invasive Keychain attribute check.
- **CONF-02** (@AppStorage + observable model + isConfigured): Satisfied — `AppSettings` is `@Observable`, persists via `@AppStorage`, exposes `isConfigured` gated on all three credentials, proven by 4 passing unit tests.
- **CONF-03** (Settings form, key to Keychain on commit): Satisfied — SecureField + server/username fields, commit only on button/onSubmit, never rehydrates the SecureField, Remove flow offered. Runtime behavior manually verified and approved by the user at the 02-03 checkpoint; static preconditions re-confirmed here.

## Independent Re-verification Performed

Did not rely on SUMMARY.md claims. Independently: full scoped test run against fresh derived data (`/tmp/mxrm-verify`) → `** TEST SUCCEEDED **`, 9/9 tests; static security sweeps (SecItem confined to KeychainService, UserDefaults/AppStorage confined to AppSettings.swift, no stored apiKey, no key logging, no data-protection/accessibility attributes, no `.shared`/`.standard` in tests); `git diff --stat project.pbxproj` empty; non-invasive Keychain attribute check; full read of all three source files plus MXRouteManagerApp.swift. No secrets printed, logged, or echoed; no Keychain items deleted or modified.

## Verdict

Phase 2 achieves its goal. All three CONF requirements are implemented, tested, and statically verified; the human checkpoint covered the runtime-only truths. No gaps found.
