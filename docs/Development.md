# Development

## Build & test commands

Every `xcodebuild` invocation needs the `DEVELOPER_DIR` prefix (on machines where `xcode-select` points at the Command Line Tools, a bare `xcodebuild` fails):

```
# Debug build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Debug -derivedDataPath /tmp/mxrm-build build

# Unit tests (scoped — skips the slow UI-test launch tests)
pkill -x MXRouteManager 2>/dev/null || true   # see Troubleshooting: a running app hangs the test host
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/mxrm-build -only-testing:MXRouteManagerTests test
```

Suite at v1.0.0: **55 tests** (Keychain round-trip, AppSettings persistence, API client via URLProtocol mocks, endpoint behavior, alias validation).

## Project conventions

- **Xcode 16 synchronized groups** (`objectVersion 77`): files added under `MXRouteManager/` or `MXRouteManagerTests/` join their targets automatically. **Never hand-edit `project.pbxproj` object entries** — build settings are the only thing edited there. Non-source placeholder files inside the app folder need a `PBXFileSystemSynchronizedBuildFileExceptionSet` (there's one for the `.gitkeep`s).
- **Swift Testing** (`@Test`/`#expect`), not XCTest. Tests that share state use `@Suite(.serialized)` — but note that only serializes *within* a suite; anything cross-suite (like `MockURLProtocol.handler`) must go through the `withMockNetwork { }` actor lock.
- **Test isolation:** tests never touch `KeychainService.shared` or `UserDefaults.standard` — isolated service names (`MXRouteManager.tests*`) and UUID-suffixed suites, cleaned up in `defer`.
- **Actor isolation:** the app target defaults to `MainActor`; the test target doesn't. Types used across that boundary (models, client, validator) are declared `nonisolated`.
- **No secrets in code or logs**: `SecItem` calls live only in `KeychainService`; `URLSession` only in `MXRouteClient`; nothing logs key material. Keychain *presence* checks are attributes-only.

## Regenerating the app icon

The icon is code-generated — edit the constants in the script and re-run:

```
/usr/bin/swift scripts/generate-appicon.swift
```

It renders all ten mac-idiom PNGs plus `Contents.json` into `Assets.xcassets/AppIcon.appiconset/`. The script lives at the repo root deliberately (outside the synchronized groups) so it's never compiled into the app.

## Planning workflow (Kata)

The project is developed with the [Kata](https://github.com/gannonh/kata-marketplace) spec-driven workflow. `.planning/` holds the full trail: PROJECT.md (vision), ROADMAP.md, STATE.md (accumulated decisions — read this before making changes; it's where the hard-won environment lessons live), per-phase plans/summaries/verifications, and milestone archives. GitHub issues track phases and stories per milestone. To start new work: `/kata-add-milestone`, then plan and execute phases.
