---
phase: 05-polish-release
verified: 2026-08-26T20:00:00Z
status: passed
score: 15/15 must-haves verified
---

# Phase 5: Polish & Release Verification Report

**Goal:** The app is presentable and ready for daily use from a Release build.
**Status:** PASSED

## Observable Truths

| # | Truth (from plan must_haves) | Evidence | Level |
|---|---|---|---|
| 1 | First-run panel makes purpose + 3 next steps obvious | `unconfiguredSection` in MenuBarContentView.swift: purpose `Text`, `setupStep(1..3)` naming `panel.mxroute.com/api-keys.php`, Server/Username, Settings save | exists/substantive/wired |
| 2 | Panel names API-key source and gets to Settings in one click | `setupStep(1)` names the URL as plain text (not `Link`, avoids popover dismissal); `Button { openSettings(); activate() }` | wired |
| 3 | Empty accounts/domains explain what's missing + what to do | `emptyState("No domains...", hint: "...server and username...")` and `emptyState("No mailboxes...", hint: "...Create one at panel.mxroute.com...")` | wired |
| 4 | Empty states offer reload | Both `emptyState` calls pass `{ Task { await model.loadDomains(force:true) } }` / `loadAccounts(...force:true)` closures | wired |
| 5 | Configured flow unaffected | `formSection`/`actionSection`/`.loaded`/`.failed`/`.idle` branches, animations, footer unchanged from 04-03 baseline | exists/substantive |
| 6 | Checkpoint fix: openSettings not SettingsLink+gesture | Confirmed no `SettingsLink`+`.borderedProminent`+`.simultaneousGesture` on welcome button; uses `@Environment(\.openSettings)` + `activate()` (commit d985cc9, present at HEAD c8baa58) | wired |
| 7 | Real app icon in bundle | `/Applications/MXRouteManager.app/Contents/Resources/AppIcon.icns` exists; `CFBundleIconName=AppIcon` | wired |
| 8 | Icon reproducible from source, no pbxproj change | `scripts/generate-appicon.swift` at root, zero hits in `project.pbxproj` grep, outside all synchronized root groups | exists/wired |
| 9 | Icon legible at small sizes | `size >= 128` detail gate present in script (`let detailed = size >= 128`) | substantive |
| 10 | Menu bar glyph unchanged | Not modified this phase (only MenuBarContentView.swift touched by 05-01; icon plan touched only assets/script) | exists |
| 11 | README covers clone→build→setup for a stranger | README.md sections: Requirements, Building (DEVELOPER_DIR-prefixed), Setup (3 credentials + `panel.mxroute.com/api-keys.php`) | substantive |
| 12 | README states non-goals | "What it does not do" section lists no list/delete, no domain/mailbox mgmt, no external destinations, no launch-at-login | substantive |
| 13 | README: Keychain-only, no real credentials | "Security" section states service `MXRouteManager` account `api-key`; only placeholder host `eagle.mxlogin.com` appears | substantive |
| 14 | Release build compiles/runs, icon+entitlements correct | Installed `/Applications/MXRouteManager.app`: `LSUIElement=true`, `AppIcon.icns` present, `network.client` entitlement true | wired |
| 15 | Repo presentable, no stray files | `.gitignore` covers build products/DerivedData/xcuserdata; `git ls-files | grep xcuserdata` empty; `git status` clean at session start | exists/wired |

## Required Artifacts

| Artifact | Present | Notes |
|---|---|---|
| MXRouteManager/Views/MenuBarContentView.swift | Yes | first-run panel + empty states + openSettings fix all present |
| scripts/generate-appicon.swift | Yes | 160 lines, AppKit/CoreGraphics only, outside synchronized groups |
| AppIcon.appiconset/ (10 PNGs + Contents.json) | Yes | all filenames present in Contents.json |
| README.md | Yes | all required content present, no real credentials |
| .gitignore | Yes | build products, .DS_Store, xcuserdata covered |

## Key Link Verification

| Link | Verified |
|---|---|
| `settings.isConfigured` drives header + content branch | Yes — single flag gates both `header` symbol/title and `content` branch |
| `openSettings()` + `activate()` brings Settings to front (post-fix) | Yes — present in welcome panel Button; old broken pattern absent |
| Empty-domains hint points at server/username fields | Yes |
| Reload buttons call `force: true` loaders | Yes, both call sites confirmed |
| `scripts/` outside synchronized groups → never compiled | Yes — zero pbxproj references, confirmed against the three listed synchronized root group paths |
| `ASSETCATALOG_COMPILER_APPICON_NAME` → actool emits `.icns` + `CFBundleIconName` | Yes — confirmed on installed bundle |
| Release build entitlements → `network.client` | Yes — confirmed via codesign on `/Applications/MXRouteManager.app` |

## Requirements Coverage

| Req | Description | Status |
|---|---|---|
| POL-01 | First-run + empty states routing/messaging | Satisfied — code-level evidence above; REQUIREMENTS.md still shows `[ ]`/Pending, a bookkeeping lag consistent with STATE.md's "awaiting phase verification" note, not a functional gap |
| POL-02 | App icon, README, Release build verified | Satisfied — icon in installed bundle, README complete and accurate, Release build's LSUIElement/icon/entitlements confirmed on `/Applications` copy |

## Independent Re-Verification Note

This pass did not re-run `xcodebuild test` (per environment rule, and because 05-03-SUMMARY.md documents a 55/55 clean-derived-data pass from its own independent post-checkpoint verification, run minutes before this phase verification). It did not launch or kill the running `/Applications/MXRouteManager.app` daily-use instance. All checks were static: source reading, plist/entitlement introspection via `PlistBuddy`/`codesign -d --entitlements :-` (no `-w`), `git ls-files`/`git log`, and file-listing on the appiconset and scripts directory. No API calls, no Keychain reads, no key material logged.

## Verdict

**PASSED.** All three plans' must-haves are verified as exists/substantive/wired against real source and the installed bundle. The one open item — REQUIREMENTS.md checkbox state — is process bookkeeping the verification/audit workflow updates next, not a gap in what was built. No human_needed: the two-round human checkpoint (Release-build demo, credential re-save with Always Allow, Test Connection, README check) was already completed and approved per 05-03-SUMMARY.md, and is treated as satisfied per the verifier's instructions.
