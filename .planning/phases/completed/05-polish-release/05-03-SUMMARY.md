---
phase: 05-polish-release
plan: "03"
subsystem: polish
tags: [readme, gitignore, release-build]
requires: [05-01, 05-02]
provides: [README, .gitignore, verified Release build, installed /Applications app]
affects: []
tech-stack:
  added: []
  patterns: [openSettings environment action for programmatic Settings opening]
key-files:
  created: [README.md, .gitignore]
  modified: [MXRouteManager/Views/MenuBarContentView.swift]
decisions:
  - "Programmatic openSettings environment action for prominent Settings buttons — SettingsLink + borderedProminent + simultaneousGesture silently swallows the action"
metrics:
  duration: "~10 min execution + two-round user verification"
  completed: "2026-08-26"
---

# Phase 5 Plan 03: README & Release Summary

Wrote the project README and `.gitignore`, verified the Release configuration builds clean with the icon/entitlements/LSUIElement all correct, and closed the milestone with a human walk of the first-run path on that Release build — which surfaced and fixed a real defect along the way.

README.md documents what the app is, requirements, the DEVELOPER_DIR-prefixed build/test commands, the three-credential setup pointing at `panel.mxroute.com/api-keys.php`, Keychain-only key storage (service `MXRouteManager`, account `api-key`), explicit non-goals (no listing/deleting forwarders, no domain/mailbox management, no external destinations, no launch-at-login), project layout, and the icon-regeneration command. No real credentials or broken image links. `.gitignore` covers `.DS_Store`, `build/`, `DerivedData/`, `*.xcuserstate`, and `xcuserdata/`; the previously-tracked `xcschememanagement.plist` was untracked with `git rm --cached` in the same commit so the ignore rule is actually true of the tree (`git ls-files | grep -c xcuserdata` → 0).

Release configuration verified from a clean `/tmp` derived-data path: `** BUILD SUCCEEDED **`, `AppIcon.icns` and `Assets.car` present in `Contents/Resources/`, `CFBundleIconName` = `AppIcon`, `LSUIElement` = `true`, and the `com.apple.security.network.client` entitlement present. No `error:` lines and no `AppIcon`/`unassigned` warnings in the build log. Regression suite stayed green at 55/55 throughout.

## Deviations from Plan

**Checkpoint-found defect, fixed in commit `d985cc9`.** During the first pass of the Task 3 checkpoint, the user reported that the welcome panel's "Open Settings…" button did nothing. Root cause: the welcome panel's `SettingsLink` combined `.buttonStyle(.borderedProminent)` with `.simultaneousGesture(TapGesture()...)` — in that combination the tap gesture won gesture arbitration and swallowed the link's action entirely (the footer's borderless `SettingsLink` was unaffected, which is why the regression suite and the Phase 4 live walk never caught it). Fixed by switching the welcome button to the programmatic `@Environment(\.openSettings)` action with `NSApplication.shared.activate()` called in the same handler, rather than relying on `SettingsLink` + a simultaneous gesture. Tests stayed 55/55; the Release build was rebuilt after the fix.

**Spotlight-stale-build wrinkle.** After the code fix, the user's first re-test launched via Spotlight, which resolved to a stale Debug build sitting in Xcode's DerivedData rather than the fixed Release build. Resolved by installing the fixed Release build to `/Applications/MXRouteManager.app` (confirming the icon, the `network.client` entitlement, and the Open Settings fix on that installed copy), deleting the stale DerivedData bundle, and cleaning `/tmp` build products so no ambiguous binary remained on disk.

**Final pass: user approved.** First-run panel renders correctly on the fixed Release build; "Open Settings…" opens the Settings window in front; credentials were re-saved with "Always Allow" chosen on the new binary's Keychain prompt; Test Connection reported the account's domains; the popover returned to the normal "New Forwarder" state; the README was checked against the setup actually performed; and the API key was confirmed saved at the end, leaving the app configured and ready for daily use.

## Post-checkpoint verification (this pass)

Ran the plan's `<verification>` section fresh, from a new clean derived-data path (`/tmp/mxrm-0503-verify`, removed afterward):

- `README.md` and `.gitignore` both present; every required term (`DEVELOPER_DIR`, `panel.mxroute.com/api-keys.php`, `Always Allow`, the Keychain service/account, `LSUIElement`, `generate-appicon`) appears; only the intended placeholders (`eagle.mxlogin.com`) appear, no real credentials, no broken `![...]()` image references; `xcuserdata` tracked count is 0.
- Clean Release build: `** BUILD SUCCEEDED **`; `AppIcon.icns` + `Assets.car` present; `CFBundleIconName` = `AppIcon`; `LSUIElement` = `true`; entitlements show `com.apple.security.network.client => 1`; no `error:`/`AppIcon`/`unassigned` findings in the log.
- Regression suite: `** TEST SUCCEEDED **`, 55 passed / 0 failed.
- `git status --short` shows only the two new files plus the `.planning` phase-folder move from `pending/` to `active/` (workflow bookkeeping, out of this plan's file scope) — no stray build products or probe files.

The user's daily-use `/Applications/MXRouteManager.app` instance (installed during the checkpoint) was running at the start of this verification pass and was killed (`pkill -x MXRouteManager`) to run the regression test suite cleanly, per the environment rule that a leftover instance hangs the test-host launch. It was not relaunched afterward — the user should relaunch it from `/Applications` (or Spotlight, now that the stale DerivedData copy has been removed) to resume daily use.
