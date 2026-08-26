---
phase: 03-mxroute-api-client
verified: 2026-08-26T13:44:21Z
status: passed
score: 36/36 must-haves verified
---

# Phase 3: MXRoute API Client Verification Report

**Goal:** A tested async API client that authenticates with the stored credentials and covers domains, email accounts, and forwarder creation.

**Status: PASSED**

## Independent Re-Verification

Ran the scoped test suite fresh (own derivedData path, `pkill -x MXRouteManager` first):

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project MXRouteManager.xcodeproj \
  -scheme MXRouteManager -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/mxrm-verify3 -only-testing:MXRouteManagerTests test
```
→ `** TEST SUCCEEDED **`, **41/41** tests passed (counted `Test case ... passed` lines directly from the run, not from the SUMMARY).

Entitlement check on the signed product from that same run:
```
codesign -d --entitlements :- /tmp/mxrm-verify3/Build/Products/Debug/MXRouteManager.app
```
→ plist contains `com.apple.security.app-sandbox = true` **and** `com.apple.security.network.client = true`.

## Observable Truths

| # | Truth (must_haves.truths) | Plan | Evidence | Status |
|---|---|---|---|---|
| 1 | Sandboxed app allowed outgoing network connections | 03-01 | `codesign -d --entitlements` on freshly built binary: `network.client => true` | ✅ |
| 2 | `{success,data}` / `{success:false,error:{code,message,field}}` both decode | 03-01 | `MXRouteModels.swift` `APIEnvelope<T>.init(from:)`; 9 passing `MXRouteModelsTests` | ✅ |
| 3 | Every failure is one `MXRouteError` case with human-readable message | 03-01 | 7-case enum, `errorDescription` for all cases, `errorDescriptionsAreUserReadable` test passing | ✅ |
| 4 | Every request carries X-API-Key/X-Server/X-Username | 03-02 | `makeRequest` sets all three; `authHeadersAreSentOnEveryRequest` passing | ✅ |
| 5 | `listDomains()` returns domain names from envelope | 03-02 | `listDomains()` impl; `listDomainsDecodesTheEnvelope`/`listDomainsReturnsEmptyArray` passing | ✅ |
| 6 | Bad key / API error / transport failure / unreadable JSON → distinct error cases | 03-02 | `send()` pipeline + `failure(status:body:)`; 6 distinct-mapping tests passing | ✅ |
| 7 | No credentials → immediate `.notConfigured`, no request sent | 03-02 | `makeRequest` guards before building URL; `missingCredentialsThrowNotConfiguredWithoutARequest` asserts `requestWasMade == false` | ✅ |
| 8 | `listEmailAccounts(domain:)` returns mailboxes sorted by address | 03-03 | `.sorted { localizedCaseInsensitiveCompare }`; `emailAccountsDecodeAndSortByAddress` passing | ✅ |
| 9 | `createForwarder` POSTs `{alias,destinations}`, returns Forwarder even on 201-empty-body | 03-03 | `CreateForwarderBody` + `created ?? Forwarder(...)` fallback; `createForwarderSynthesizesResultWhenBodyIsEmpty` passing | ✅ |
| 10 | Duplicate alias / validation rejection surface API's own code/message/field | 03-03 | `duplicateAliasSurfacesConflict`, `validationErrorCarriesTheField` passing, asserting exact `.api(code:message:field:)` | ✅ |
| 11 | Domain escaped as single URL path segment | 03-03 | `pathSegmentAllowed` (urlPathAllowed minus `/`); `domainIsEncodedAsASinglePathSegment` passing (`%2F`, `%20`, no `/../`) | ✅ |
| 12 | Test Connection button disabled until server/username/key present | 03-04 | `.disabled(!settings.isConfigured \|\| isTesting)` in `SettingsView.swift:56` | ✅ |
| 13 | Progress indicator while running, re-enables after (success or failure) | 03-04 | `isTesting` `@State` + `ProgressView`; `defer { isTesting = false }` inside `Task` | ✅ |
| 14 | Valid credentials report domain count | 03-04 | code path verified + **human checkpoint already confirmed** (2 real domains) | ✅ |
| 15 | Wrong API key shows MXRoute's decoded message | 03-04 | `catch { errorMessage = (error as? MXRouteError)?.errorDescription ?? ... }`; human checkpoint confirmed decoded message shown, not generic/raw | ✅ |

## Required Artifacts

| Artifact | Plan | Present |
|---|---|---|
| `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` in both Debug/Release configs | 03-01 | ✅ (`grep -c` → 2) |
| `MXRouteModels.swift` — `EmailAccount`, `Forwarder`, `APIEnvelope<T>`, `APIErrorBody`, `MXRouteError` | 03-01 | ✅ all five types present |
| `MXRouteModelsTests.swift` — decoding + error-description tests | 03-01 | ✅ 9 `@Test` |
| `MXRouteClient.swift` — credentials, injectable session/baseURL, `send()`, `listDomains()`, `live(settings:)` | 03-02 | ✅ all present |
| `MockURLProtocol.swift` — stub, request capture, `makeMockSession()` | 03-02 | ✅ |
| `MXRouteClientTests.swift` — headers/decoding/error tests | 03-02 | ✅ 11 `@Test` |
| `MXRouteClient.swift` extended with `listEmailAccounts`/`createForwarder` | 03-03 | ✅ |
| `MXRouteEndpointTests.swift` — path/body/decoding/error tests | 03-03 | ✅ 12 `@Test` |
| `SettingsView.swift` — Test Connection row wired to `MXRouteClient.live(settings:).listDomains()` | 03-04 | ✅ |

## Key Link Verification

| Link | Verified how | Status |
|---|---|---|
| `ENABLE_OUTGOING_NETWORK_CONNECTIONS` → codesigned `network.client` entitlement | Dumped signed binary, not build setting | ✅ |
| `APIEnvelope<T>.data` Optional → represents bodiless 201 | `envelopeWithNoDataDecodes` test + `send()` `nil`-on-empty-body path | ✅ |
| `MXRouteError` Equatable → exact `#expect(error == .api(...))` assertions | Used throughout both client test suites | ✅ |
| `init(...)` with defaults → prod passes nothing, tests inject mock session/baseURL, no `#if DEBUG` | `grep` confirms zero `#if DEBUG` in `MXRouteClient.swift` | ✅ |
| `live(settings:keychain:)` reads `AppSettings` + `KeychainService.load()`, client holds no reference to either | `@MainActor extension`, `(try? keychain.load()) ?? nil` snapshot pattern | ✅ |
| `send()` returns `T?`, single status+envelope→error mapping | Both endpoint plans reuse it; no second `URLRequest(` construction found (`grep -n "URLRequest("` → only inside `makeRequest`) | ✅ |
| Both endpoints call `send()` (auth/error mapping inherited, not reimplemented) | Read source: `listEmailAccounts`/`createForwarder` both call `send(...)`, no ad hoc networking | ✅ |
| `send()` `T?` → `createForwarder` falls back to synthesized `Forwarder` on empty 201 | `created ?? Forwarder(...)` present and tested | ✅ |
| `capturedBody` (httpBodyStream drain) → POST body assertions read real bytes | Used in `createForwarderPostsAliasAndDestinations`/`destinationsAreTrimmedBeforeSending`, parsed via `JSONSerialization` (never raw-string compared, as required) | ✅ |
| Button → `Task` → `live(settings:)` → `listDomains()`, entitlement lets it leave sandbox | Code path + human checkpoint (real 2-domain response) | ✅ |
| `catch` reads `(error as? MXRouteError)?.errorDescription` | Exact line present in `SettingsView.swift:128` | ✅ |
| `isTesting` gates both `ProgressView` and button `disabled` | Both reference the same `@State` | ✅ |

## Documented Deviations — Independently Verified

1. **03-01: `hasKey` made attributes-only (no `kSecReturnData`).** Confirmed in `KeychainService.swift:95-106` — `hasKey` sets `kSecReturnAttributes`, never `kSecReturnData`; the secret-reading `load()` is a separate method used only on demand. This matches the documented fix for the launch-time ACL-prompt hang.
2. **03-03: cross-suite `withMockNetwork` lock.** Confirmed `MockNetworkLock` actor + `withMockNetwork` helper exist in `MockURLProtocol.swift`, and **every** `@Test` in both `MXRouteClientTests.swift` and `MXRouteEndpointTests.swift` wraps its body in `try await withMockNetwork { ... }` (verified by reading both files in full — no test sets `MockURLProtocol.handler` outside the wrapper). Running both suites together in the independent test run above passed 41/41 with no flakiness observed.

## Source Sweeps

- `URLSession` appears only in `MXRouteClient.swift` (init default + `live` factory param). ✅
- `SecItem*` appears only in `KeychainService.swift`. ✅
- No `print(`/`NSLog` in `MXRouteClient.swift`, `MXRouteModels.swift`, or `SettingsView.swift`. ✅
- No `api.mxroute.com` in `MXRouteManagerTests/` (only `api.mxroute.test` mock host). ✅
- No `KeychainService.shared`/`UserDefaults.standard` in test target. ✅
- `project.pbxproj` diff at HEAD contains exactly the 2 `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;` lines (already committed; no uncommitted app-code changes — only a Kata plan-file directory move is pending in git status). ✅

## Requirements Coverage

| Requirement | Description | Status |
|---|---|---|
| API-01 | Async URLSession client authenticates with X-API-Key/X-Server/X-Username from Keychain | Satisfied |
| API-02 | Codable models + envelope decoding map failures to typed `MXRouteError` | Satisfied |
| API-03 | `listDomains()` returns domain names | Satisfied |
| API-04 | `listEmailAccounts(domain:)` returns a domain's email accounts | Satisfied |
| API-05 | `createForwarder(domain:alias:destinations:)` creates a forwarder, surfaces validation errors | Satisfied |
| API-06 | Unit tests cover auth headers, envelope decoding, error mapping via URLProtocol mock | Satisfied (41/41, headers/decoding/6+ error mappings) |
| CONF-04 | Test Connection calls `GET /domains`, reports success/domain-count or decoded error | Satisfied (code + human checkpoint) |

Note: `.planning/REQUIREMENTS.md` still shows these as unchecked/"Pending" — that appears to be pending doc housekeeping (normally flipped at phase close-out), not a functional gap; every requirement is independently confirmed satisfied above.

## Verdict

**PASSED.** All 15 observable truths, 9 required artifacts, and 12 key links across plans 03-01–03-04 are independently verified against the real source tree and a fresh, independent test run (41/41), not merely asserted by the SUMMARY files. Both documented deviations (attributes-only `hasKey`, cross-suite `withMockNetwork` lock) are present and functioning in source. The human checkpoint for CONF-04's live-network behavior was already completed and is treated as satisfied per instructions. No gaps found.
