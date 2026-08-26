---
phase: 01-app-shell-foundation
verified: 2026-08-25T21:15:00Z
status: passed
score: 8/8 must-haves verified
---

# Phase 1: App Shell & Foundation Verification Report

**Goal:** The app lives in the menu bar as a compact popover with a clean project structure, ready to host features.
**Verified:** 2026-08-25T21:15:00Z
**Status:** PASSED

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Launching puts an SF Symbol icon in menu bar, no Dock icon | ✅ Verified (build precondition) + human-approved runtime | `INFOPLIST_KEY_LSUIElement = YES;` ×2 in pbxproj; built `Info.plist` extracts `LSUIElement` = `true`. Human checkpoint at 01-02 confirmed no Dock icon at launch. |
| 2 | Clicking icon opens window-style popover with placeholder content | ✅ Verified (static) + human-approved runtime | `MXRouteManagerApp.swift`: `MenuBarExtra(...) { MenuBarContentView() }.menuBarExtraStyle(.window)`. `MenuBarContentView.swift` has headline, subheadline, Divider, Quit button. Human confirmed rounded panel (not dropdown). |
| 3 | Popover has a Quit button that terminates the app | ✅ Verified | `MenuBarContentView.swift`: `Button("Quit") { NSApplication.shared.terminate(nil) }`. Human confirmed Quit works. |
| 4 | No SwiftData template UI anywhere | ✅ Verified | `grep -rn "SwiftData\|WindowGroup" MXRouteManager/` → no matches. `Item.swift`/`ContentView.swift` confirmed deleted from filesystem. |
| 5 | Settings entry point in popover | ✅ Verified | `MenuBarContentView.swift`: `SettingsLink { Label("Settings…", ...) }.simultaneousGesture(... NSApplication.shared.activate() ...)`. |
| 6 | Settings scene wired, opens in front | ✅ Verified (static) + human-approved runtime | `MXRouteManagerApp.swift`: `Settings { SettingsView() }` scene present. Human confirmed window opens in front. |
| 7 | Settings shows placeholder, no credential fields | ✅ Verified | `grep -rn "SecureField\|AppStorage\|Keychain\|URLSession" MXRouteManager/` → no matches. `SettingsView.swift` contains only a `Form`/`Section` with static text. |
| 8 | Closing Settings leaves app running, no Dock icon | ✅ Human-approved (runtime-only) | Confirmed at 01-02 checkpoint, approved by user. |

## Required Artifacts

| Artifact | Status | Notes |
|---|---|---|
| `MXRouteManager/App/MXRouteManagerApp.swift` | ✅ Exists, substantive, wired | Single `App` with `MenuBarExtra` (`.window` style) + `Settings` scenes, no `WindowGroup`. |
| `MXRouteManager/Views/MenuBarContentView.swift` | ✅ Exists, substantive, wired | Referenced by `MenuBarExtra` body; contains Quit + SettingsLink. |
| `MXRouteManager/Views/SettingsView.swift` | ✅ Exists, substantive, wired | Referenced by `Settings` scene body. |
| `MXRouteManager/Models/.gitkeep`, `MXRouteManager/Services/.gitkeep` | ✅ Exist | Confirmed present; verified they do NOT leak into built app bundle Resources via `PBXFileSystemSynchronizedBuildFileExceptionSet`. |
| `MXRouteManager/Item.swift`, `MXRouteManager/ContentView.swift` | ✅ Deleted | Confirmed absent from filesystem. |

## Key Link Verification

| Link | Status | Evidence |
|---|---|---|
| `INFOPLIST_KEY_LSUIElement = YES` in both app-target configs → built `LSUIElement` true | ✅ | grep count = 2 in pbxproj; independent rebuild to `/tmp/mxrm-verify` → `plutil -extract LSUIElement raw ...` = `true` |
| `MenuBarExtra + .menuBarExtraStyle(.window)` → popover not pull-down | ✅ | Present in source; human-confirmed panel style, not dropdown |
| `MACOSX_DEPLOYMENT_TARGET = 15.0` at project level → built `LSMinimumSystemVersion` 15.0 | ✅ | grep count = 4 (0 remaining `26.5`); independent build → `LSMinimumSystemVersion` = `15.0` |
| Synchronized groups auto-pick-up App/Views/Models/Services | ✅ | All 3 new `.swift` files compile and link with zero manual `PBXFileReference`/`PBXBuildFile` edits (only a documented exception-set addition to exclude `.gitkeep` from Resources, per 01-01-SUMMARY deviation) |
| `Settings { SettingsView() }` scene → `SettingsLink` target | ✅ | Both declared; human confirmed SettingsLink opens the window |
| `NSApplication.shared.activate()` on tap → window surfaces for LSUIElement app | ✅ | Present as `.simultaneousGesture`; human confirmed window opens in front |

## Requirements Coverage

- **APP-01** (menu-bar-only app, `.window` style, no Dock icon, macOS 15+): Satisfied — `LSUIElement=true`, `LSMinimumSystemVersion=15.0`, `.menuBarExtraStyle(.window)`, no `WindowGroup`.
- **APP-02** (compact popover UI; App/Models/Services/Views structure; reachable Settings scene): Satisfied — folder structure present and populated correctly, popover has stable `.frame(width: 320)`, Settings scene reachable via `SettingsLink`.

## Independent Re-verification Performed

Ran a clean build from scratch (`derivedDataPath /tmp/mxrm-verify`, distinct from any prior build artifacts) — `** BUILD SUCCEEDED **`. Re-extracted `LSUIElement` (`true`) and `LSMinimumSystemVersion` (`15.0`) directly from the produced `Info.plist`. Confirmed no `.gitkeep` files leak into `Contents/Resources`. Confirmed pbxproj diff since the initial template commit is small (20 insertions / 4 deletions) and consistent with the documented deviation (build settings + one exception-set object).

## Verdict

Phase 1 goal is achieved. All 8 must-have truths across both plans verified against real source and an independent from-scratch build — not just plan claims. The runtime-only checkpoints were human-approved and their static preconditions independently confirmed. No gaps found.
