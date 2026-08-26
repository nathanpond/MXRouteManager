---
phase: 04-create-forwarder-ui
plan: "01"
subsystem: create-forwarder
tags: [validation, observable, state-machine, swift-testing]
requires: [03-02, 03-03]
provides: [AliasValidator, CreateForwarderModel]
affects: [04-02, 04-03]
tech-stack:
  added: []
  patterns:
    - "Pure nonisolated enum + static validate() function for form validation, kept free of SwiftUI so the nonisolated test target can use it directly"
    - "@Observable @MainActor model with @ObservationIgnored @AppStorage + access(keyPath:)/withMutation(keyPath:) for persisted selection (same idiom as AppSettings)"
    - "Credential-fingerprint-gated cache (domains) plus per-key dictionary cache (accounts by domain), both invalidated together on credential change"
    - "Double cancellation guard on async loads: Task.isCancelled for task-id cancellation, plus an identity check (domain == selectedDomain) for late-arriving responses a cancelled-task check alone would miss"
    - "Injectable makeClient closure defaulting to MXRouteClient.live(settings:) so previews/tests can substitute a credential-less client"
key-files:
  created:
    - MXRouteManager/Models/AliasValidator.swift
    - MXRouteManager/Models/CreateForwarderModel.swift
    - MXRouteManagerTests/AliasValidatorTests.swift
  modified: []
decisions:
  - "AliasValidator rule order is fixed: @ check before charset check, so pasting a full address gets a specific 'enter just the part before the @' message instead of a generic invalid-character one"
  - "Lowercasing happens inside validate(), before charset/dot checks, so normalization and validation can't disagree about what the final alias looks like"
  - "reset() (Create Another) intentionally keeps selectedDomain and selectedDestination — only aliasInput and submitState clear, matching the plan's 'same domain, same mailbox' repeat-case assumption"
  - "submit() does not check Task.isCancelled — a create is a completed server-side side effect, so its result is always reported rather than silently dropped"
metrics:
  duration: "~25 min"
  completed: "2026-08-26"
---

Built the non-visual half of the create-forwarder flow exactly as planned, no deviations from the spec.

`AliasValidator.validate(_:)` is a pure `nonisolated` function returning `.empty` / `.valid(normalized:)` / `.invalid(reason:)`, running the 9 ordered checks (trim, `@`, whitespace, length, lowercase-normalize, charset, leading/trailing dot, double dot) exactly as specified. No `import SwiftUI`. 14 Swift Testing cases in `AliasValidatorTests.swift` cover empty, valid, normalization, outer-whitespace trim, allowed punctuation, each invalid reason, and both length boundaries (64 valid / 65 invalid) — more than the ≥11 called for.

`CreateForwarderModel` is an `@Observable @MainActor` class exposing `domains`/`accounts` (`LoadState<Value>`), `aliasInput`/`aliasValidation`/`previewAddress`, `selectedDomain` (persisted to `mxroute.lastDomain` via the `AppSettings` `@ObservationIgnored @AppStorage` + `access(keyPath:)`/`withMutation(keyPath:)` idiom), `selectedDestination`, `submitState` (`SubmitState`), and `canSubmit`. `loadDomains` is gated by a credential fingerprint (server|username|hasAPIKey, never the key itself) so a repeat popover open is instant and a credential change invalidates both the domain cache and the per-domain `accountsCache` dictionary. `loadAccounts` guards every state write with both `Task.isCancelled` and `domain == selectedDomain` so a fast domain switch or a late-arriving response can never paint a stale error banner. `reconcileSelectedDomain`/`reconcileDestination` keep the picker bound to a value that actually exists in the freshly loaded list. `submit()` builds a real `MXRouteClient` through the injectable `makeClient` closure and calls `createForwarder(domain:alias:destinations:)` with the normalized alias — no stubbed result. `reset()` clears only `aliasInput`/`submitState`, keeping domain and destination selected for the next alias.

No deviations from the plan; both tasks matched their `<action>` blocks directly. One fix needed during Task 1's verify step: the test file used `String.localizedCaseInsensitiveContains`, which requires `import Foundation` (not just `Testing`) in the nonisolated test target — added the import, no other changes.

All verification passed: build succeeded, full suite green at `** TEST SUCCEEDED **`, 55 tests total (41 pre-existing + 14 new), `project.pbxproj` untouched (`git diff --stat` empty), `URLSession`/`SecItem` matches confined to `Services/MXRouteClient.swift` and `Services/KeychainService.swift`, no `import SwiftUI` in `AliasValidator.swift`, and `MXRouteManager/Views/`/`MXRouteManager/App/` untouched.

Ready for 04-02 (the view that renders this model) and 04-03 (the live-checkpoint wiring): `LoadState`/`SubmitState` are `Equatable` as required for `.animation(_:value:)`, and `makeClient` is injectable for `#Preview` use without a real network call or Keychain prompt.
