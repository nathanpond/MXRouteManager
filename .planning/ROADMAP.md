# Roadmap: MXRouteManager

## Overview

A lightweight macOS menu bar app (SwiftUI MenuBarExtra) for creating MXRoute email forwarders: pick a domain, type an alias, pick the destination account, create. API key lives in the Keychain; the whole flow takes seconds.

## Milestones

- 🔄 **v1.0.0 MVP** — Phases 1-5 (in progress)

## Current Milestone: v1.0.0 MVP

**Goal:** Ship a menu bar app where a configured user can create an MXRoute email forwarder end-to-end in under ten seconds.

- [x] Phase 1: App Shell & Foundation (2/2 plans) — completed 2026-08-25
- [x] Phase 2: Credentials & Configuration (3/3 plans) — completed 2026-08-26
- [x] Phase 3: MXRoute API Client (4/4 plans) — completed 2026-08-26

### Phase 4: Create-Forwarder UI

**Goal:** The core flow works end-to-end and looks sleek: domain → alias → destination → create.
**Demo:** Click the menu bar icon, pick a domain, type "sales", pick a destination account, press Create — a confirmation shows `sales@domain → destination`, and the forwarder exists in MXRoute.
**Requirements:** UI-01, UI-02, UI-03, UI-04, UI-05
**Plans:** 3 plans

**Plans:**
- [ ] 04-01: Alias validator and the create-forwarder state model (UI-02)
- [ ] 04-02: Popover flow — domain, alias, destination, create (UI-01, UI-02, UI-03, UI-04)
- [ ] 04-03: Visual design pass + live create checkpoint (UI-05)

**Success Criteria:**
1. Domain dropdown loads asynchronously on popover open with loading, error, and retry states
2. Alias field validates the local part and disables Create until valid
3. Destination picker shows the selected domain's accounts (full addresses) and reloads when the domain changes
4. Create shows progress, then a success confirmation with the full route, surfaces API errors inline, and resets the form
5. The popover uses material background, SF Symbols, and consistent spacing/typography in both light and dark

---

### Phase 5: Polish & Release

**Goal:** The app is presentable and ready for daily use from a Release build.
**Demo:** Delete credentials, relaunch — the popover routes to Settings with guidance; restore credentials, build Release, and use the app icon-adorned build daily.
**Requirements:** POL-01, POL-02
**Plans:** TBD

**Success Criteria:**
1. Unconfigured launch routes the user to Settings with clear guidance; empty domains/accounts show helpful messaging
2. App icon and menu bar icon are set; README documents setup including where to create the API key
3. Release build compiles and runs correctly

---

## Progress Summary

| Milestone | Phases | Plans | Status      | Shipped |
| --------- | ------ | ----- | ----------- | ------- |
| v1.0.0    | 5 (3 ✓) | 12    | In Progress | —       |

---
*Roadmap created: 2026-08-25*
*Last updated: 2026-08-26 — Phase 3 completed and verified; Phase 4 planned*
