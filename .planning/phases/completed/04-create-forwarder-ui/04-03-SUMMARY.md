---
phase: 04-create-forwarder-ui
plan: "03"
subsystem: create-forwarder
tags: [swiftui, design, materials, sf-symbols]
requires: [04-02]
provides: [styled popover, verified live create flow]
affects: [phase-5-polish]
tech-stack:
  added: []
  patterns: [semantic colors + materials, Equatable-driven animations, monospaced address styling]
key-files:
  created: []
  modified: [MXRouteManager/Views/MenuBarContentView.swift]
decisions: []
metrics:
  duration: "~5 min execution + user verification"
  completed: "2026-08-26"
---

# Phase 4 Plan 03: Visual Design Pass Summary

Restyled `MenuBarContentView` into a native-feeling macOS menu bar popover and verified the entire Phase 4 create-forwarder demo against the live MXRoute account.

## What was built

- Replaced the single-padding layout with a three-band `VStack` (header / content / footer) at zero outer spacing, `.frame(width: 320)`, `.background(.regularMaterial)`, and a `Divider()` above the footer.
- Header: `arrow.turn.down.right` symbol + "New Forwarder" headline.
- Every field label is now an SF Symbol-led `Label` (`globe` for Domain, `at` for Alias, `tray.and.arrow.down` for Destination, `arrow.clockwise` for retries, `checkmark.circle.fill` multicolor for success, `exclamationmark.triangle.fill` for inline errors, `key` for the unconfigured nudge, `gearshape` for Settings), all in `.caption.weight(.medium)` / `.secondary` / `.imageScale(.small)`.
- Four-step typography scale (`.headline`, `.subheadline.weight(.semibold)`, default body, `.caption`) plus the two monospaced exceptions: the live `alias@domain` preview and the confirmation route.
- Semantic colors only (`.primary`/`.secondary`/`.tint`/`.red`/materials) — no hardcoded RGB, no `preferredColorScheme`.
- `.animation(.snappy(duration: 0.2), value: model.submitState)` and `.animation(.easeInOut(duration: 0.15), value:)` on `model.domains` / `model.accounts`, driven by the `Equatable` state enums from plan 04-01; no animation on `aliasInput` so typing stays responsive.
- Footer buttons switched to `.borderless` / `.controlSize(.small)`, Quit set to `.secondary` so Settings reads as primary.
- Fixed-size wrapping on the confirmation route (`.lineLimit(2)`) and inline error text so long strings wrap within 320pt instead of resizing the popover.

## Verification

- Build: `** BUILD SUCCEEDED **`.
- Full test suite: 55 passed, 0 failed, `** TEST SUCCEEDED **` — no regression from the design-only change.
- Grep checks: no `Color(red:`, no `Color(white:`, no `preferredColorScheme`, no `GroupBox`/`Form {` in `MenuBarContentView.swift`.
- `project.pbxproj` diff: empty (no new files, no hand-edits).
- Scope check: `SettingsView.swift`, `Services/`, `Models/` all clean — only `MenuBarContentView.swift` changed.

## Human checkpoint (Task 2) — approved

The user ran the full live demo against their real MXRoute account and confirmed every observation:

- Async domain load populated the picker without a button press.
- All three validation states (invalid full-address alias, alias with spaces, valid alias) displayed their specific inline messages with no popover resize.
- The destination list reloaded correctly on domain switch, showing only the new domain's mailboxes.
- A real forwarder, `kata-test-1`, was created and independently confirmed to exist in `panel.mxroute.com` under that domain's Forwarders, with the confirmation line matching exactly.
- The duplicate-alias retry (`kata-test-1` again) surfaced MXRoute's own rejection message inline, in red, with the form preserved.
- `kata-test-2` (Create Another → type → Return) completed comfortably under ten seconds end-to-end, with domain and destination remembered.
- The last-used domain persisted across a quit/relaunch cycle.
- Both Light and Dark appearance rendered clean: translucent material background, readable labels in both, correct accent-colored Create button.
- All SF Symbols rendered (no empty-box glyphs from a mistyped name).

This is the only verification of this phase that no unit test can provide, since none of the suite's tests cross the live network.

## Deviations

None. The plan was followed as written; the documented `.regularMaterial` fallback was not needed — the user confirmed the material background looked correct as shipped in both appearances.
