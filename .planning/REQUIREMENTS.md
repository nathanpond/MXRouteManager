# Requirements: MXRouteManager

**Defined:** 2026-08-25
**Core Value:** Creating a new email forwarder takes under ten seconds from clicking the menu bar icon.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### App Shell

- [x] **APP-01**: App runs as a menu-bar-only app (MenuBarExtra, `.window` style, no Dock icon) on macOS 15+
- [x] **APP-02**: Clicking the menu bar icon opens a compact popover with the app UI; project is structured into App/Models/Services/Views groups with a reachable Settings scene

### Configuration

- [x] **CONF-01**: API key is saved to, read from, and deletable from the macOS Keychain via a KeychainService (Security framework, no third-party deps)
- [x] **CONF-02**: Server hostname (X-Server) and DirectAdmin username (X-Username) persist via @AppStorage, exposed through an observable settings model with an "is configured" state
- [x] **CONF-03**: Settings UI provides a SecureField for the API key and fields for server + username; the key is written to the Keychain on commit
- [ ] **CONF-04**: A Test Connection action calls `GET /domains` and reports success (domain count) or a decoded API error

### API Client

- [ ] **API-01**: MXRouteClient (async/await URLSession) authenticates every request with X-API-Key, X-Server, and X-Username headers, reading the key from the Keychain
- [ ] **API-02**: Codable models (EmailAccount, Forwarder) and success/error envelope decoding map failures to a typed MXRouteError
- [ ] **API-03**: `listDomains()` returns the account's domain names
- [ ] **API-04**: `listEmailAccounts(domain:)` returns the email accounts for a domain
- [ ] **API-05**: `createForwarder(domain:alias:destinations:)` creates a forwarder and surfaces API validation errors
- [ ] **API-06**: Unit tests cover auth headers, envelope decoding, and error mapping via a URLProtocol mock

### Create-Forwarder UI

- [ ] **UI-01**: Domain dropdown loads asynchronously on popover open with loading, error, and retry states
- [ ] **UI-02**: Alias field validates the local part (non-empty, no spaces/@, allowed characters); Create is disabled until valid
- [ ] **UI-03**: Destination picker lists email accounts on the selected domain, reloading when the domain changes, showing full addresses
- [ ] **UI-04**: Create action submits with a progress state, shows a success confirmation (`alias@domain → destination`), surfaces API errors inline, and resets the form for the next entry
- [ ] **UI-05**: Visual design pass: compact sleek layout, material background, SF Symbols, proper spacing/typography, light + dark

### Polish

- [ ] **POL-01**: First-run and empty states: unconfigured app routes to Settings; empty domains/accounts show helpful messaging
- [ ] **POL-02**: App icon and menu bar icon set; README documents setup (API key from panel.mxroute.com/api-keys.php); Release build verified

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Management

- **MGMT-01**: List and delete existing forwarders per domain
- **MGMT-02**: Free-text (external) forwarder destinations
- **MGMT-03**: Launch-at-login toggle

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Email account / domain management | Panel already covers this; app stays focused on forwarder creation |
| Multiple MXRoute accounts | Single personal account is the use case |
| iOS/iPadOS | Menu bar concept is macOS-only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| APP-01 | Phase 1 | Complete |
| APP-02 | Phase 1 | Complete |
| CONF-01 | Phase 2 | Complete |
| CONF-02 | Phase 2 | Complete |
| CONF-03 | Phase 2 | Complete |
| CONF-04 | Phase 3 | Pending |
| API-01 | Phase 3 | Pending |
| API-02 | Phase 3 | Pending |
| API-03 | Phase 3 | Pending |
| API-04 | Phase 3 | Pending |
| API-05 | Phase 3 | Pending |
| API-06 | Phase 3 | Pending |
| UI-01 | Phase 4 | Pending |
| UI-02 | Phase 4 | Pending |
| UI-03 | Phase 4 | Pending |
| UI-04 | Phase 4 | Pending |
| UI-05 | Phase 4 | Pending |
| POL-01 | Phase 5 | Pending |
| POL-02 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-25*
*Last updated: 2026-08-26 after Phase 2 completion*
