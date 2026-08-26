---
phase: 05-polish-release
plan: "01"
subsystem: polish
tags: [swiftui, first-run, empty-states]
requires: [04-02, 04-03]
provides: [first-run guidance, empty-state messaging]
affects: [05-03]
tech-stack:
  added: []
  patterns: [state-aware header driven by a single isConfigured flag, Text concatenation for inline monospaced URL segments, shared emptyState(_:hint:reload:) helper for symbol-led non-error empty states with a force:true reload action]
key-files:
  created: []
  modified: [MXRouteManager/Views/MenuBarContentView.swift]
decisions:
  - "Header symbol/title now branches on settings.isConfigured (envelope.badge/'MXRoute Manager' vs arrow.turn.down.right/'New Forwarder') so the title never says 'New Forwarder' above a setup panel"
  - "panel.mxroute.com/api-keys.php stays plain text, not a Link — opening a browser from this LSUIElement popover would dismiss it, which reads as a crash on first run"
  - "Empty domain/mailbox lists render via a shared emptyState helper (info.circle, secondary text, Reload button) instead of the .red Retry-style treatment used for .failed — an empty list is a state of the account, not an error"
  - "Both new Reload buttons call loadDomains(force: true) / loadAccounts(for:force:) so a mailbox or domain created in the MXRoute panel is actually picked up (CreateForwarderModel caches per-domain and would otherwise no-op)"
metrics:
  duration: "~12 min"
  completed: "2026-08-26"
---

Turned the one-line unconfigured stub into a real first-run panel (state-aware header, purpose line, three numbered setup steps naming panel.mxroute.com/api-keys.php, prominent "Open Settings…" with the activate() gesture preserved) and replaced the two bare empty-state sentences (no domains / no mailboxes) with symbol-led messages that name the likely cause and offer a force:true Reload. No deviations from the plan — both tasks implemented verbatim as specified, including the plain-text (non-Link) URL and the emptyState helper kept distinct from the red .failed treatment. Build succeeded both times; full regression suite (55/55 tests) stayed green; only MenuBarContentView.swift was modified across two commits.
