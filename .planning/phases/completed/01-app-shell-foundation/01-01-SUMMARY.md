---
phase: 01-app-shell-foundation
plan: "01"
subsystem: app-shell
tags: [swiftui, menubarextra, lsuielement, xcode]
requires: []
provides: [menu-bar shell, App/Models/Services/Views structure, macOS 15 target]
affects: [01-02, phase-2-settings, phase-4-ui]
tech-stack:
  added: []
  patterns: [MenuBarExtra .window style, generated Info.plist via INFOPLIST_KEY_*, PBXFileSystemSynchronizedBuildFileExceptionSet for non-source files]
key-files:
  created:
    - MXRouteManager/App/MXRouteManagerApp.swift
    - MXRouteManager/Views/MenuBarContentView.swift
    - MXRouteManager/Models/.gitkeep
    - MXRouteManager/Services/.gitkeep
  modified:
    - MXRouteManager.xcodeproj/project.pbxproj
  deleted:
    - MXRouteManager/Item.swift
    - MXRouteManager/ContentView.swift
decisions:
  - "Used the modern synchronized-groups PBXFileSystemSynchronizedBuildFileExceptionSet mechanism to exclude Models/.gitkeep and Services/.gitkeep from the app target's Resources build phase, rather than avoiding .gitkeep files — this is the sanctioned Xcode 16+ way to exclude specific paths from a target and does not touch legacy PBXFileReference/PBXBuildFile objects."
metrics:
  duration: "~20 minutes"
  completed: "2026-08-25"
---

# Phase 1 Plan 01: MenuBarExtra Shell Summary

Replaced the SwiftData/NavigationSplitView Xcode template with a macOS-15, Dock-icon-free MenuBarExtra shell (`.window` style, placeholder popover, working Quit button) and the App/Models/Services/Views folder layout every later phase builds on.

## What Was Built

**Task 1 — Build settings (commit `ed3c40d`):** Replaced all four `MACOSX_DEPLOYMENT_TARGET = 26.5;` occurrences (project Debug/Release, `MXRouteManagerTests` Debug/Release) with `15.0`, and added `INFOPLIST_KEY_LSUIElement = YES;` to both the app target's Debug and Release build configurations, positioned immediately before `INFOPLIST_KEY_NSHumanReadableCopyright`.

**Task 2 — Structure (commit `220f644`):** `git rm`'d `Item.swift` (the SwiftData `@Model`) and `ContentView.swift` (the `NavigationSplitView` template); created `App/`, `Models/`, `Services/`, `Views/` under `MXRouteManager/`; `git mv`'d `MXRouteManagerApp.swift` into `App/`; added `.gitkeep` placeholders in `Models/` and `Services/`. `Assets.xcassets` was left in place as instructed.

**Task 3 — MenuBarExtra shell (commit `6aa9abb`):** Rewrote `App/MXRouteManagerApp.swift` as a single `MenuBarExtra("MXRoute Manager", systemImage: "envelope.badge") { MenuBarContentView() }.menuBarExtraStyle(.window)` scene — no SwiftData, no `ModelContainer`, no `WindowGroup`. Created `Views/MenuBarContentView.swift`: headline title, secondary-foreground placeholder line, `Divider()`, and a bottom row with a `// Settings entry point added in plan 01-02` marker and a "Quit" button calling `NSApplication.shared.terminate(nil)` (`import AppKit` added explicitly). `.padding(16)` + `.frame(width: 320)` for a stable popover size, plus a plain `#Preview`.

Verified end-to-end: `xcodebuild ... clean build` → `** BUILD SUCCEEDED **`; built `Info.plist` extracts `LSUIElement` = `true` and `LSMinimumSystemVersion` = `15.0`; `find MXRouteManager -name '*.swift'` lists exactly the two new files; no `SwiftData`/`Item`/stray `WindowGroup` references remain anywhere in `MXRouteManager/`.

## Deviations from Plan

- **Build-blocking bug in the plan's stated assumption, auto-fixed.** The plan's `<execution_context>` asserted "Xcode's synchronized groups ignore dot-files, so `.gitkeep` placeholders are safe and will not end up in a build phase." This was incorrect on this Xcode/objectVersion-77 project: both `Models/.gitkeep` and `Services/.gitkeep` were picked up by the app target's synchronized group and both copied to the same bundle path (`Contents/Resources/.gitkeep`), producing `error: Multiple commands produce '.../Contents/Resources/.gitkeep'` on the Task 3 build.
  - Fix: added one `PBXFileSystemSynchronizedBuildFileExceptionSet` object (`membershipExceptions = (Models/.gitkeep, Services/.gitkeep)`, scoped to the `MXRouteManager` target) and referenced it from the existing `MXRouteManager` `PBXFileSystemSynchronizedRootGroup` via a new `exceptions` array entry.
  - This is the Xcode 16+ sanctioned mechanism for excluding specific synchronized-group paths from a target's build phases — distinct from, and not a violation of, the plan's ban on hand-adding legacy `PBXFileReference`/`PBXBuildFile`/`PBXGroup` objects (that ban is about not reverting the project to the pre-synchronized-groups format). No other object types were added; no existing object was restructured.
  - Verified post-fix: `.gitkeep` no longer appears anywhere under the built `.app` bundle, and the build succeeds cleanly.
  - This is documented here rather than silently absorbed because plan `<verification>` item 5 expected the pbxproj diff to contain "only build-setting lines changed... no added/removed object entries" — that expectation no longer holds exactly; the diff also contains this one exception-set addition, which was necessary for the build (and thus the phase) to succeed at all.

No other deviations. All three tasks were otherwise executed exactly as written.

## Next Plan Readiness

01-02 (Settings scene + `SettingsLink`) can proceed immediately:
- The `// Settings entry point added in plan 01-02` marker is in place in `MenuBarContentView.swift`'s bottom row, ready for a `SettingsLink` insertion.
- `App/`, `Models/`, `Services/` exist and are empty (aside from `.gitkeep`), ready for Keychain/API-client/settings-model code.
- The app builds and launches as a menu-bar-only, Dock-icon-free process, so 01-02 can add a `Settings` scene without fighting template residue.
- Note for 01-02 (and any later plan adding non-source files to `Models/`/`Services/`): the synchronized-groups exception-set precedent above should be reused/extended rather than re-solved from scratch if another non-source file needs to be excluded from a build phase.
