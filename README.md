# MXRouteManager

A macOS menu bar app for creating MXRoute email forwarders in seconds. Click the menu bar icon, pick a domain, type an alias, pick the destination mailbox, press Create.

## What it looks like

Clicking the menu bar icon opens a 320pt translucent popover. A Domain menu lists the domains on your MXRoute account; an Alias field shows a live `alias@domain` preview as you type, with inline validation if the alias is empty or contains invalid characters; a "Forward to" menu lists the mailboxes available on the selected domain; and a Create button submits the forwarder, followed by a short confirmation line once it succeeds.

## Documentation

Full docs live in the [project wiki](https://github.com/nathanpond/MXRouteManager/wiki): [Getting Started](https://github.com/nathanpond/MXRouteManager/wiki/Getting-Started) · [Development](https://github.com/nathanpond/MXRouteManager/wiki/Development) · [Architecture](https://github.com/nathanpond/MXRouteManager/wiki/Architecture) · [Troubleshooting](https://github.com/nathanpond/MXRouteManager/wiki/Troubleshooting). Release history in [CHANGELOG.md](CHANGELOG.md).

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16 or later to build
- An MXRoute account with API access
- No third-party dependencies — SwiftUI and Foundation only

## Building

```
git clone <repo> && cd MXRouteManager

# Debug build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Debug -derivedDataPath /tmp/mxrm-build build

# Release build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Release -derivedDataPath /tmp/mxrm-release build

# Tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/mxrm-build -only-testing:MXRouteManagerTests test
```

The `DEVELOPER_DIR` prefix pins the Xcode toolchain; without it `xcodebuild` may resolve to the Command Line Tools and fail.

The app is `LSUIElement` — it has no Dock icon and no Cmd-Tab entry. After `open`ing the built app, look for the envelope icon in the **menu bar**, not the Dock. Opening the project in Xcode and pressing Run works too.

## Setup

1. Sign in at `https://panel.mxroute.com` and go to **API Keys** (`panel.mxroute.com/api-keys.php`). Create a key and copy it — it is shown once.
2. That page also shows the values for **Server** (your mail server hostname, e.g. `eagle.mxlogin.com`) and **Username** (your DirectAdmin username). They also appear in your MXRoute welcome email.
3. Launch the app, open **Settings** from the popover (or the menu bar item's Settings…), enter Server, Username, and paste the API Key, then press **Save to Keychain**.
4. Press **Test Connection** — it fetches your domain list and reports how many domains it found. The first call from a newly built binary triggers a macOS Keychain prompt; choose **Always Allow** so it does not ask again.

## Security

The API key is stored in the macOS Keychain as a generic password (service `MXRouteManager`, account `api-key`) and is never written to `UserDefaults`, a preference file, a log, or the repository. Server hostname and username are not secret and live in `UserDefaults` via `@AppStorage`. Presence of the key is checked attributes-only so that merely launching the app does not read the secret. The app talks only to `https://api.mxroute.com`.

## What it does not do

This is a deliberate MVP scope, not missing work:

- It does not list or delete existing forwarders (use the MXRoute panel).
- It does not create or manage domains or mailboxes.
- Destinations are limited to mailboxes on the selected domain — no external forwarding addresses.
- There is no launch-at-login option.

## Project layout

```
MXRouteManager/App/          MenuBarExtra + Settings scene
MXRouteManager/Models/       AppSettings, CreateForwarderModel, AliasValidator, API models
MXRouteManager/Services/     KeychainService, MXRouteClient
MXRouteManager/Views/        MenuBarContentView (the popover), SettingsView
MXRouteManagerTests/         55 Swift Testing cases
scripts/generate-appicon.swift   regenerates the app icon PNGs
.planning/                   roadmap, requirements, and per-phase plans
```

## Development

The app icon is generated, not hand-drawn: `swift scripts/generate-appicon.swift` re-renders every PNG in `Assets.xcassets/AppIcon.appiconset` plus its `Contents.json`, so icon changes are edits to that script. Tests are Swift Testing (`@Test`), run with the command above. The project was built phase by phase with the Kata workflow; `.planning/ROADMAP.md` and `.planning/phases/` hold the plans and verification records if you want the history.
