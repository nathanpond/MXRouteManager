# MXRouteManager Documentation

A macOS menu bar app for creating [MXRoute](https://mxroute.com) email forwarders in seconds: click the menu bar icon, pick a domain, type an alias, pick the destination mailbox, press Create. Built with SwiftUI + Foundation only (no third-party dependencies), macOS 15+.

**Current version:** v1.0.0 (shipped 2026-08-26) — see [CHANGELOG](../CHANGELOG.md)

## Pages

| Page | What's in it |
|---|---|
| [Getting Started](Getting-Started.md) | Install, credentials setup, first run, Keychain behavior |
| [Development](Development.md) | Build/test commands, project conventions, icon regeneration, planning workflow |
| [Architecture](Architecture.md) | Components, data flow, and the design decisions behind them |
| [Troubleshooting](Troubleshooting.md) | Known gotchas — Keychain prompts, test-runner hangs, stale builds |

## At a glance

- **Core value:** a new forwarder in under ten seconds from clicking the menu bar icon (human-timed at release).
- **Scope (v1):** create-only. No forwarder listing/deletion, no account/domain management, destinations limited to mailboxes on the selected domain. The DirectAdmin panel covers the rest.
- **Security:** the API key lives only in the macOS Keychain (generic password, service `MXRouteManager`, account `api-key`). Server hostname and username are non-secret and live in UserDefaults.
- **v2 candidates:** forwarder list/delete, free-text external destinations, launch-at-login.

## Project links

- [README](../README.md) — quick start
- [CHANGELOG](../CHANGELOG.md) — release history
- `.planning/` — the Kata planning trail: [milestone archive](../.planning/milestones/v1.0.0-ROADMAP.md), [audit report](../.planning/v1.0.0-MILESTONE-AUDIT.md), per-phase plans/summaries/verifications under `.planning/phases/completed/`
