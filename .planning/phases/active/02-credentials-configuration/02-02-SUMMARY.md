---
phase: 02-credentials-configuration
plan: "02"
subsystem: credentials
tags: [observable, appstorage, settings-model, swift-testing]
requires: [02-01]
provides: [AppSettings model with serverHostname/username/hasAPIKey/isConfigured, environment injection]
affects: [02-03, phase-3-api-client, phase-4-ui]
tech-stack:
  added: []
  patterns: [ "@ObservationIgnored @AppStorage paired with manual access(keyPath:)/withMutation(keyPath:) to make @AppStorage persistence coexist with @Observable in a plain class", "hasAPIKey as a stored property mutated by saveAPIKey/removeAPIKey rather than a computed keychain.hasKey, so SwiftUI observes key-state changes without hitting the Keychain on every render", "init(store:keychain:) constructor injection for isolated-suite / isolated-Keychain testing" ]
key-files:
  created: [MXRouteManager/Models/AppSettings.swift, MXRouteManagerTests/AppSettingsTests.swift]
  modified: [MXRouteManager/App/MXRouteManagerApp.swift]
decisions:
  - "Primary @ObservationIgnored @AppStorage + access/withMutation pattern compiled on the first attempt — no fallback to plain stored properties + didSet was needed"
  - "Trimming happens only in isConfigured, saveAPIKey, and normalize() — never inside the serverHostname/username setters — so a bound TextField can hold a leading/trailing space mid-edit"
  - "hasAPIKey is a stored Bool seeded from keychain.hasKey at init and flipped explicitly by saveAPIKey/removeAPIKey; the model never re-reads the Keychain to answer hasAPIKey"
  - "No apiKey property exists on AppSettings — the key is written straight through to KeychainService.save/delete and never cached on the model"
metrics:
  duration: "~15 minutes"
  completed: "2026-08-26"
---

Built `AppSettings`, the single `@Observable` source of truth for MXRoute credentials: `serverHostname` and `username` persist through `@AppStorage`-backed private storage (observed manually via `access(keyPath:)`/`withMutation(keyPath:)` since `@Observable` cannot see through `@AppStorage`'s `DynamicProperty` machinery), `hasAPIKey` is a stored flag seeded from and kept in sync with `KeychainService`, and `isConfigured` composes all three into one truth. `init(store:keychain:)` makes both the defaults suite and the Keychain service pair injectable, which four Swift Testing tests exploit: relaunch persistence via a second instance over the same isolated `UserDefaults` suite, `isConfigured`'s three-credential gate, `hasAPIKey` flipping on save/remove, and whitespace-only values being excluded until `normalize()` runs. Every test uses a fresh UUID-suffixed suite name plus the isolated `"MXRouteManager.tests.settings"` Keychain pair, cleaned up with `defer`. `MXRouteManagerApp` now owns one `@State private var settings = AppSettings()` and applies `.environment(settings)` to both the `MenuBarExtra` popover and the `Settings` window content, since environment does not cross scene boundaries.

Deviations: None — the plan's primary `@ObservationIgnored @AppStorage` + `access`/`withMutation` pattern compiled without needing the documented `didSet` fallback.

Verification: Debug build succeeded after each task. Scoped test run reported `** TEST SUCCEEDED **` with all 4 `AppSettingsTests` cases plus the 4 `KeychainServiceTests` cases from plan 02-01 plus the template test — 9 total, all passing. `grep -rn "UserDefaults\|AppStorage" MXRouteManager/` matches only inside `Models/AppSettings.swift`. No stored `apiKey` property anywhere on the model. No `environmentObject` usage anywhere in the app. No changes to `MXRouteManager/Views/` or `project.pbxproj` in this plan.

Next-plan readiness: plan 02-03 can bind `SettingsView` directly to the injected `AppSettings` environment object (`serverHostname`, `username`, `hasAPIKey`, `isConfigured`, `saveAPIKey(_:)`, `removeAPIKey()`) to replace the Phase 1 placeholder.
