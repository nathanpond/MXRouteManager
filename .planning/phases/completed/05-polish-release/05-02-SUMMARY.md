---
phase: 05-polish-release
plan: "02"
subsystem: polish
tags: [app-icon, coregraphics, asset-catalog]
requires: []
provides: [AppIcon asset set, icon generator script]
affects: [05-03]
tech-stack:
  added: []
  patterns: [CoreGraphics icon generation, actool asset discovery without pbxproj edits]
key-files:
  created: [scripts/generate-appicon.swift, MXRouteManager/Assets.xcassets/AppIcon.appiconset/*]
  modified: []
decisions:
  - "Drew the icon in code (CoreGraphics/AppKit) rather than sourcing an SVG, since no SVG rasterizer exists in PATH on this machine — the PNGs in git are a reproducible build product of the script, not hand-exported art."
  - "Kept the script at scripts/ (repo root), outside all three PBXFileSystemSynchronizedRootGroup paths, so it is never swept into a compiled target."
  - "Rewrote AppIcon.appiconset/Contents.json with filename keys on every entry — the Xcode template shipped with none, which is why the app previously built with a blank icon despite a successful build."
  - "Gated the forwarding-arrow motif on size >= 128 per the plan's design constants; 16/32px renders keep only a heavier-stroke envelope to stay legible instead of turning to mud."
metrics:
  duration: "~15m"
  completed: "2026-08-26"
---

Built `scripts/generate-appicon.swift`, a standalone AppKit/CoreGraphics script (no SwiftUI/UIKit imports) that renders all ten mac-idiom PNGs (16/32/128/256/512 at 1x/2x) plus a filename-bearing `Contents.json` into `AppIcon.appiconset`, using the macOS Big Sur icon grid (824/1024 body, 0.2250 corner radius), a blue→indigo gradient, a white envelope, and a forwarding arrow gated on `size >= 128`.

Ran the script, then built the app with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ... -derivedDataPath /tmp/mxrm-build-0502 build`: the built bundle carries `Contents/Resources/AppIcon.icns` and `CFBundleIconName = AppIcon` in Info.plist, with no `CompileAssetCatalog` warnings. Visually confirmed the 1024px render (blue→indigo rounded square, white envelope + arrow) and the 32px render (clean envelope, arrow dropped, no mud), and confirmed Finder shows the new icon on the built `.app` via `open -R`.

Confirmed reproducibility: deleted all ten PNGs and re-ran `swift scripts/generate-appicon.swift` — `git status --short` on the appiconset showed no diff, i.e. byte-identical regeneration.

Ran the regression suite (`pkill -x MXRouteManager` first, own `-derivedDataPath /tmp/mxrm-build-0502`, `-only-testing:MXRouteManagerTests`): **55/55 tests passed**, `** TEST SUCCEEDED **`. `git diff --stat MXRouteManager.xcodeproj/project.pbxproj` stayed empty throughout — no pbxproj edits were made or needed. The menu bar glyph (`MenuBarExtra("MXRoute Manager", systemImage: "envelope.badge")` in `MXRouteManagerApp.swift`) was left untouched.

No deviations from the plan. Both tasks matched the plan's exact source and constants; only the derivedDataPath was changed (`/tmp/mxrm-build-0502` instead of the plan's `/tmp/mxrm-build`) to avoid lock contention with a concurrently-running executor building plan 05-01 in the same repo working tree.

Commits:
- `bece6c2` — `feat(05-02): add CoreGraphics app icon generator script` (scripts/generate-appicon.swift only)
- `06c917c` — `feat(05-02): generate app icon PNGs and asset catalog entries` (Contents.json + 10 PNGs only)
