# Roadmap: MXRouteManager

## Overview

A lightweight macOS menu bar app (SwiftUI MenuBarExtra) for creating MXRoute email forwarders: pick a domain, type an alias, pick the destination account, create. API key lives in the Keychain; the whole flow takes seconds.

## Milestones

- 🔄 **v1.0.0 MVP** — Phases 1-5 (in progress)

## Current Milestone: v1.0.0 MVP

**Goal:** Ship a menu bar app where a configured user can create an MXRoute email forwarder end-to-end in under ten seconds.

- [x] Phase 1: App Shell & Foundation (2/2 plans) — completed 2026-08-25

### Phase 2: Credentials & Configuration

**Goal:** The user can configure and persist all three MXRoute credentials, with the API key held only in the Keychain.
**Demo:** Open Settings, paste an API key into a secure field, enter server hostname and username, quit and relaunch — values persist and the key is visible in Keychain Access, not in UserDefaults.
**Requirements:** CONF-01, CONF-02, CONF-03
**Plans:** TBD

**Success Criteria:**
1. KeychainService saves, loads, and deletes the API key using the Security framework (no third-party deps)
2. Server hostname and username persist via @AppStorage and are exposed through an observable settings model with an "is configured" state
3. Settings UI offers a SecureField for the key plus fields for server and username; the key is written to the Keychain on commit
4. The API key never appears in UserDefaults or on disk

---

### Phase 3: MXRoute API Client

**Goal:** A tested async API client that authenticates with the stored credentials and covers domains, email accounts, and forwarder creation.
**Demo:** Press Test Connection in Settings with valid credentials — it reports the number of domains; with a bad key it shows the decoded API error message.
**Requirements:** API-01, API-02, API-03, API-04, API-05, API-06, CONF-04
**Plans:** TBD

**Success Criteria:**
1. MXRouteClient sends X-API-Key (from Keychain), X-Server, and X-Username headers on every request to https://api.mxroute.com
2. `listDomains()`, `listEmailAccounts(domain:)`, and `createForwarder(domain:alias:destinations:)` decode the `{success, data}` envelope; failures map to a typed MXRouteError carrying the API's code/message
3. Test Connection in Settings calls `listDomains()` and reports success or the decoded error
4. URLProtocol-mocked unit tests pass for auth headers, decoding, and error mapping

---

### Phase 4: Create-Forwarder UI

**Goal:** The core flow works end-to-end and looks sleek: domain → alias → destination → create.
**Demo:** Click the menu bar icon, pick a domain, type "sales", pick a destination account, press Create — a confirmation shows `sales@domain → destination`, and the forwarder exists in MXRoute.
**Requirements:** UI-01, UI-02, UI-03, UI-04, UI-05
**Plans:** TBD

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
| v1.0.0    | 5 (1 ✓) | 2     | In Progress | —       |

---
*Roadmap created: 2026-08-25*
*Last updated: 2026-08-25 — Phase 1 completed and verified*
