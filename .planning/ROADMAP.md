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
- [x] Phase 4: Create-Forwarder UI (3/3 plans) — completed 2026-08-26

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
| v1.0.0    | 5 (4 ✓) | 15    | In Progress | —       |

---
*Roadmap created: 2026-08-25*
*Last updated: 2026-08-26 — Phase 4 completed and verified*
