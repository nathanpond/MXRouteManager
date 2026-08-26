# Milestones: MXRouteManager

## ✅ v1.0.0 MVP — SHIPPED 2026-08-26

**Goal:** Ship a menu bar app where a configured user can create an MXRoute email forwarder end-to-end in under ten seconds.

**Stats:** 5 phases · 15 plans · 66 commits · 34 files · +2,694/−110 lines · 55 unit tests · 2 days (2026-08-25 → 2026-08-26)

**Key accomplishments:**

1. Menu-bar-only SwiftUI app (MenuBarExtra, no Dock icon) with a sleek material popover, light + dark
2. End-to-end create-forwarder flow — domain → validated alias → destination → create — human-timed under ten seconds
3. Fully tested MXRoute API client (header auth, typed errors, URLProtocol-mocked suite)
4. Keychain-only API key handling with attributes-only presence checks (no launch prompts)
5. First-run guidance, empty states, generated app icon, README, verified sandboxed Release build
6. Every phase independently goal-backward verified (105 must-haves total) plus five human-approved checkpoints including two live-API demos

**Archives:** [Roadmap](milestones/v1.0.0-ROADMAP.md) · [Requirements](milestones/v1.0.0-REQUIREMENTS.md) · [Audit](v1.0.0-MILESTONE-AUDIT.md)
**Tag:** v1.0.0
