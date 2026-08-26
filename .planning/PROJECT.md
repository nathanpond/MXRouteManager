# MXRouteManager

## What This Is

A lightweight macOS menu bar app (SwiftUI `MenuBarExtra`) for creating MXRoute email forwarders in seconds: pick a domain from a dropdown, type a forwarder alias, pick the destination email account, hit create. Built for a single user managing their own MXRoute account without opening the DirectAdmin panel.

## Core Value

Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.

## Current State (v1.0.0, shipped 2026-08-26)

The app is complete and in daily use from a Release build installed at /Applications/MXRouteManager.app. All v1 requirements shipped and validated: menu-bar-only shell, Keychain-backed credentials with Settings + Test Connection, fully tested API client, the under-ten-second create-forwarder flow, first-run guidance, app icon, README. 55 unit tests green; tagged v1.0.0.

## Next Milestone Goals

Not yet defined — run `/kata-add-milestone` to scope v1.1. Leading candidates from the v2 backlog: forwarder list/delete (MGMT-01), free-text external destinations (MGMT-02), launch-at-login (MGMT-03).

## Requirements

### Validated

- ✓ Menu-bar-only app (no Dock icon) with a compact popover UI, macOS 15+ — v1.0.0
- ✓ MXRoute API client for domains, email accounts, and forwarders — v1.0.0
- ✓ API key stored in the macOS Keychain via KeychainService; server hostname and username configurable in Settings — v1.0.0
- ✓ Create-forwarder flow: domain dropdown → alias field → destination account picker → create — v1.0.0 (human-timed under ten seconds)
- ✓ Clean, sleek native UI (materials, SF Symbols, light/dark) — v1.0.0

### Active

(None — between milestones)

### Out of Scope

- Forwarder listing/deletion — create-only MVP; revisit in v2
- Email account / domain management (create/delete) — panel already covers this; app stays focused
- Free-text (external) forwarder destinations — destinations are accounts on the selected domain only
- Launch-at-login — nice-to-have, not core value
- iOS/iPadOS — macOS menu bar concept only

## Context

- Xcode project (template replaced in Phase 1). Repo: https://github.com/nathanpond/MXRouteManager (private).
- MXRoute API: `https://api.mxroute.com` (OpenAPI at `/openapi.yaml`). Auth via three headers: `X-API-Key` (secret), `X-Server` (mail server hostname, e.g. `eagle.mxlogin.com`), `X-Username` (DirectAdmin username). API keys are created at panel.mxroute.com/api-keys.php.
- Response envelope: `{success, data}` on success, `{success, error: {code, message, field}}` on failure.
- Endpoints used: `GET /domains` (also serves as credential test), `GET /domains/{domain}/email-accounts`, `POST /domains/{domain}/forwarders` with `{alias, destinations: [String]}`.

## Constraints

- **Tech stack**: SwiftUI + Foundation only, no third-party dependencies — keeps the app lightweight
- **Platform**: macOS 15 Sequoia minimum — unlocks modern SwiftUI; personal-use app
- **Security**: API key must live in the Keychain, never in UserDefaults or on disk

## Key Decisions

| Decision | Rationale | Outcome |
| -------- | --------- | -------- |
| Create-only MVP (no forwarder list/delete) | Core value is fast creation; management exists in panel | ✓ Good |
| Destination picker limited to accounts on the selected domain | One API call, simplest flow | ✓ Good |
| API key in Keychain; X-Server/X-Username in @AppStorage | Only the key is secret | ✓ Good |
| macOS 15 minimum | Personal machines are current; newest SwiftUI APIs | ✓ Good |

---
*Last updated: 2026-08-26 after v1.0.0 milestone completion*
