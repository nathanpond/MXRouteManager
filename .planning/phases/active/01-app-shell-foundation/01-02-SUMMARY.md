---
phase: 01-app-shell-foundation
plan: "02"
subsystem: app-shell
tags: [swiftui, settings, settingslink]
requires: [01-01]
provides: [Settings scene, SettingsLink entry point, verified Phase 1 demo path]
affects: [phase-2-settings]
tech-stack:
  added: []
  patterns: [Settings scene + SettingsLink, NSApplication.shared.activate() for accessory-app window surfacing]
key-files:
  created: [MXRouteManager/Views/SettingsView.swift]
  modified: [MXRouteManager/App/MXRouteManagerApp.swift, MXRouteManager/Views/MenuBarContentView.swift]
decisions: []
metrics:
  duration: "~5 min execution + user verification"
  completed: "2026-08-25"
---

# Phase 1 Plan 02: Settings Scene Summary

Added a reachable, placeholder Settings scene to the menu bar shell and closed out Phase 1 with a full manual demo-path verification.

## What was built

- `MXRouteManager/Views/SettingsView.swift`: a placeholder `SettingsView` with a `Form` (`.formStyle(.grouped)`), one `Section("MXRoute Credentials")` noting that API key, server, and username fields arrive in Phase 2, a `.frame(width: 420, height: 200)`, and a `#Preview`. No `SecureField`, `AppStorage`, or Keychain code — Phase 2 owns credential storage.
- `MXRouteManager/App/MXRouteManagerApp.swift`: added a top-level `Settings { SettingsView() }` scene alongside the existing `MenuBarExtra` scene, which is what makes `SettingsLink` and the standard macOS Settings window available.
- `MXRouteManager/Views/MenuBarContentView.swift`: replaced the plan 01-02 marker with a `SettingsLink` ("Settings…", gearshape icon) placed before the `Spacer()`, paired with a `.simultaneousGesture(TapGesture().onEnded { NSApplication.shared.activate() })` so the Settings window surfaces in front even though the app is an `LSUIElement` accessory app. The Quit button is unchanged.

## Human checkpoint passed

Task 3 (checkpoint:human-verify) was approved by the user. All six manual demo steps were confirmed:
1. No Dock icon appears and no window opens on launch.
2. An envelope SF Symbol appears in the menu bar.
3. Clicking it opens a window-style popover (not a plain dropdown menu).
4. Clicking "Settings…" opens the Settings window in front of other apps, showing placeholder credentials content and no input fields.
5. Closing Settings leaves the app running in the menu bar.
6. Clicking "Quit" terminates the app and the menu bar icon disappears.

## Verification

- Clean build: `** BUILD SUCCEEDED **`.
- `find MXRouteManager -name '*.swift'` lists exactly `App/MXRouteManagerApp.swift`, `Views/MenuBarContentView.swift`, `Views/SettingsView.swift`.
- `grep -rn "SecureField|AppStorage|Keychain|URLSession" MXRouteManager/` returns no matches.
- `project.pbxproj` unchanged by this plan (fileSystemSynchronizedGroups picked up the new file automatically).

## Deviations

None - plan executed exactly as written.
