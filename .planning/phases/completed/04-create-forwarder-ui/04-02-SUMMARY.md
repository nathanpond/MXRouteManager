---
phase: 04-create-forwarder-ui
plan: "02"
subsystem: create-forwarder
tags: [swiftui, menubarextra, popover-flow]
requires: [04-01]
provides: [functional create-forwarder popover flow]
affects: [04-03]
tech-stack:
  added: []
  patterns:
    - "App-scoped @Observable model (CreateForwarderModel) built in MXRouteManagerApp.init() alongside AppSettings and injected into the MenuBarExtra scene via .environment(), so the domain/mailbox cache survives closing the popover"
    - "@Bindable var model = model` declared locally in body and in each section's computed property to get $model bindings from an @Environment(CreateForwarderModel.self) property"
    - ".task(id: model.selectedDomain) for the destination reload — cancels the previous in-flight load automatically on domain change, which the model's Task.isCancelled guards depend on"
    - "Always-present reserved caption row under the alias field (validation reason / live alias@domain preview / a space) to stop the popover from resizing per keystroke"
    - "submitState-driven @ViewBuilder switch for the action section: default branch (Create button + progress + inline API error) vs .succeeded branch (server-confirmed confirmation + Create Another), with formSection hidden entirely once succeeded"
key-files:
  created: []
  modified:
    - MXRouteManager/App/MXRouteManagerApp.swift
    - MXRouteManager/Views/MenuBarContentView.swift
decisions:
  - "Followed the plan's stub-and-replace discipline exactly: Task 1 installed EmptyView() stubs for formSection/actionSection with '// replaced in Task N' markers; Task 2 replaced formSection only; Task 3 replaced actionSection only. No stub markers remain in the final file."
  - "Alias-field auto-focus implemented via .onChange(of: model.domains) (the plan's stated alternative to inlining it in .task(id:)) rather than appending logic to the domain-load task body — keeps the domain-load task free of view-focus concerns"
  - "body's if/else on model.submitState (.succeeded hides formSection, everything else shows form + action) lives in MenuBarContentView.body per the plan's explicit instruction, not inside actionSection or formSection themselves"
metrics:
  duration: "~20 min"
  completed: "2026-08-26"
---

Rebuilt the Phase 1 placeholder popover into the full create-forwarder flow: `MXRouteManagerApp` now builds one `CreateForwarderModel` from the shared `AppSettings` in `init()` and injects it into the `MenuBarExtra` scene, and `MenuBarContentView` renders every state of it — unconfigured nudge, domain/alias/destination sections with loading/failed+Retry/empty/loaded states, live `alias@domain` preview, Create with progress and disabled-until-valid gating, server-confirmed success with Create Another, and inline API-error text with the form left intact. The unchanged Settings+Quit footer (with its `NSApplication.shared.activate()` gesture) and 320pt width were preserved verbatim as instructed.

No deviations from the plan. All three tasks matched their `<action>` blocks directly:
- Task 1 — app-scope model + shell with `EmptyView()` stubs, network-free `#Preview` using `MXRouteClient(credentials: nil)`.
- Task 2 — `domainField`/`aliasField`/`destinationField` replacing the `formSection` stub; destination reload via `.task(id: model.selectedDomain)`, not `.onChange`.
- Task 3 — `actionSection` replacing its stub; success reads `forwarder.email`/`forwarder.destinations.first` (never the raw typed input), failure leaves the form populated, `.keyboardShortcut(.defaultAction)` makes Return drive both Create and Create Another.

All verification passed: build succeeded after every task, full suite green at `** TEST SUCCEEDED **` (55/55 — no regression from plan 04-01's baseline), `project.pbxproj` diff empty, no `URLSession`/`SecItem`/`createForwarder(` matches in `MXRouteManager/Views/` (the view only ever calls into the model), and `SettingsView.swift`/`Services/` untouched. Smoke check: built app launched cleanly via `open` and was killed with `pkill -x MXRouteManager` with no crash; a full interactive walkthrough (domain menu populating against a real account, Create disabled with an empty alias) was not visually inspected in this non-interactive environment but the underlying `.task`/`canSubmit` wiring verified by grep and by the green test suite covers the same logic.

Ready for 04-03: the view is fully wired and stub-free (no `EmptyView()` or `// replaced in Task N` markers remain), leaving only the visual design pass (materials, colors, card backgrounds, spacing) and the live-checkpoint verification that plan 04-03 owns.
