# Troubleshooting

Real issues hit during development, with causes and fixes. Most were caught by the phase verification gates; all are guarded against in the current code.

## macOS keeps prompting for Keychain access

**Symptom:** "MXRouteManager wants to access key…" prompts on API calls.
**Cause:** the Keychain item's ACL is bound to the app's code signature. Every rebuild (and every copy at a new path) is a "new" app to the keychain.
**Fix:** click **Always Allow** once per binary. If you clicked plain "Allow", you'll be re-prompted — Always Allow stops it. This is normal during development; a stable installed copy prompts once, ever.

## `xcodebuild test` fails: "The test runner hung before establishing connection"

**Cause 1 (most common):** an instance of MXRouteManager.app is already running — the test host can't launch a second instance. **Fix:** `pkill -x MXRouteManager` before testing.
**Cause 2:** the app blocks at launch on a modal (historically: a Keychain ACL prompt caused by reading secret data during `AppSettings.init`; fixed by making `hasKey` attributes-only — don't reintroduce secret reads at launch).

## Bare `xcodebuild` fails ("unable to find utility" / tool errors)

**Cause:** `xcode-select` points at `/Library/Developer/CommandLineTools`.
**Fix:** prefix every invocation with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run `sudo xcode-select -s /Applications/Xcode.app`).

## Spotlight/`open` launches an old version of the app

**Symptom:** a bug you just fixed is still there.
**Cause:** Spotlight indexes every `MXRouteManager.app` bundle on disk — Xcode DerivedData products, `/tmp` build outputs — and may resolve to a stale one. macOS also won't start a second instance: "launching" a new build can silently activate the old running one.
**Fix:** keep exactly one canonical copy in `/Applications`; delete stale bundles (`mdfind "kMDItemFSName == 'MXRouteManager.app'"` finds them); `pkill -x MXRouteManager` before relaunching a fresh build.

## A prominent Settings button does nothing

**Cause:** `SettingsLink` + `.buttonStyle(.borderedProminent)` + `.simultaneousGesture(TapGesture…)` — the gesture wins arbitration and swallows the link's action, silently. (The same gesture on a borderless `SettingsLink` is fine.)
**Fix:** use the programmatic `@Environment(\.openSettings)` action in a plain `Button`, and call `NSApplication.shared.activate()` in the same handler so the window surfaces in front of other apps (this is an `LSUIElement` accessory app — without activation, windows can open behind everything).

## Tests interfere with each other / flaky mock responses

**Cause:** Swift Testing's `@Suite(.serialized)` only serializes within one suite. Two suites sharing `MockURLProtocol.handler` (a `nonisolated(unsafe) static`) can run concurrently and clobber each other.
**Fix:** every test that sets the handler wraps its body in `withMockNetwork { }` (the actor-backed lock in `MockURLProtocol.swift`). Follow that pattern for any new client tests.

## Build fails: "Multiple commands produce …/Resources/.gitkeep"

**Cause:** Xcode 16 synchronized groups do **not** skip dot-files; two `.gitkeep`s at different paths collide on the same bundle-relative Resources destination.
**Fix:** the project carries a `PBXFileSystemSynchronizedBuildFileExceptionSet` excluding them. If you add non-source placeholder files under `MXRouteManager/`, add them to that exception set (via Xcode's target-membership UI, not hand-editing).

## New Swift file isn't compiling into the app

Files under `MXRouteManager/` and `MXRouteManagerTests/` join their targets automatically (synchronized groups). If a file must NOT be compiled (scripts, docs), put it outside those folders — that's why `scripts/generate-appicon.swift` lives at the repo root.
