# Architecture

## Components

```
MXRouteManager/
├── App/
│   └── MXRouteManagerApp.swift      MenuBarExtra (.window) + Settings scenes;
│                                    owns the single AppSettings and CreateForwarderModel
├── Models/
│   ├── AppSettings.swift            @Observable settings: server/username (@AppStorage),
│   │                                hasAPIKey (stored Bool), isConfigured, save/removeAPIKey
│   ├── CreateForwarderModel.swift   @Observable state machine for the create flow
│   ├── AliasValidator.swift         Pure, nonisolated local-part validation (ordered rules)
│   └── MXRouteModels.swift          Codable API surface: envelope, EmailAccount,
│                                    Forwarder, typed MXRouteError
├── Services/
│   ├── KeychainService.swift        SecItem generic-password save/load/delete/hasKey
│   └── MXRouteClient.swift          async URLSession client, header auth, send() pipeline
└── Views/
    ├── MenuBarContentView.swift     The popover: first-run panel / create form / states
    └── SettingsView.swift           Credential form + Test Connection
```

## Data flow

- **One `AppSettings`**, created in `MXRouteManagerApp.init()`, injected via `.environment` into **both** scenes. `CreateForwarderModel` is built from that same instance and injected into the MenuBarExtra scene — it's **app-scoped**, so domain/mailbox caches survive popover closes (that's what makes repeat creates near-instant).
- Views never touch the Keychain or the network. `SettingsView` → `AppSettings.saveAPIKey/removeAPIKey` → `KeychainService`. The popover → `CreateForwarderModel` → `MXRouteClient`.
- `MXRouteClient.live(settings:)` snapshots credentials (`MXRouteCredentials`, a plain `Sendable` value — not a closure over the observable model) at call time, reading the key from the Keychain **only at that moment**.
- All three endpoints (`listDomains`, `listEmailAccounts`, `createForwarder`) run through one `send()` pipeline: auth headers, HTTP-status check **before** envelope decode (a non-JSON 5xx maps to an API error, not a decoding error; 401 always maps to `.unauthorized`), typed `MXRouteError` out.

## Design decisions that matter

| Decision | Why |
|---|---|
| Keychain presence checks are attributes-only (`kSecReturnAttributes`, never `kSecReturnData`) | Reading secret data triggers the macOS ACL prompt; any re-signed binary invalidates prior approval, and a launch-time prompt hangs both the app and the unit-test host. Secrets are read at point of use only. |
| `hasAPIKey` is a stored Bool mutated by save/remove, not computed from the Keychain | Keeps SwiftUI observation working and avoids a Keychain hit per render. |
| `@Observable` + `@AppStorage` via `@ObservationIgnored` storage + `access(keyPath:)`/`withMutation(keyPath:)` accessors | The Observation macro can't see through `DynamicProperty`; this pattern makes persisted values observable. |
| Injectable `session`/`baseURL` on the client (no `#if DEBUG`) | Tests mock the network with a session-scoped `URLProtocol` against `api.mxroute.test`; production passes nothing. |
| `createForwarder` synthesizes a local `Forwarder` on the API's bodiless 201 | A successful create must never be reported as a decoding failure. |
| `.task(id: selectedDomain)` + `Task.isCancelled` + `domain == selectedDomain` guards | Fast domain switching can't paint stale results or stale errors. |
| Prominent Settings buttons use the `openSettings` environment action | A styled `SettingsLink` with an attached gesture loses gesture arbitration and silently does nothing (the borderless footer link is fine). |
| Path segments percent-encoded with `.urlPathAllowed` minus `/` | A domain string can't re-route the request (`example.com/../admin` stays one segment). |

## Sandbox & entitlements

App Sandbox is on; outgoing network access comes from the `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` build setting (two lines in `project.pbxproj`, no `.entitlements` file). Verify entitlements on a built product with `codesign -d --entitlements :- <app>`.
