# Getting Started

## Install

Build a Release copy and put it in `/Applications`:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MXRouteManager.xcodeproj -scheme MXRouteManager \
  -configuration Release -derivedDataPath /tmp/mxrm-release build
cp -R /tmp/mxrm-release/Build/Products/Release/MXRouteManager.app /Applications/
open /Applications/MXRouteManager.app
```

The app is `LSUIElement`: no Dock icon, no Cmd-Tab entry. Look for the **envelope icon in the menu bar**. (In Finder, the app bundle shows the blue/indigo envelope-and-arrow icon.)

## First run

An unconfigured launch shows a welcome panel with the three setup steps:

1. Create an API key at `panel.mxroute.com/api-keys.php`. The same page shows your **server hostname** (e.g. `something.mxrouting.net`) and **DirectAdmin username**.
2. Press **Open Settings…**.
3. Enter server hostname and username, paste the API key into the secure field, and press **Save to Keychain**. The field clears immediately — the key is never displayed again.

Press **Test Connection** to confirm: it reports the number of domains on your account, or the decoded MXRoute error if something's wrong.

## Creating a forwarder

Click the menu bar icon → pick a **Domain** → type the **Alias** (just the part before `@`; a live preview shows the full address, with inline validation) → pick **Forward to** (a mailbox on that domain) → **Create Forwarder** (or press Return). A confirmation shows the full route, e.g. `sales@example.com → me@example.com`. **Create Another** clears the alias and keeps your domain/destination for rapid entry.

The app remembers your last-used domain across launches, and caches domain/mailbox lists while it runs — repeat creates are near-instant.

## Keychain behavior (worth knowing)

- The key is stored as a generic password: service `MXRouteManager`, account `api-key`, in your login keychain (visible in Keychain Access.app).
- The app checks *whether* a key exists using an attributes-only query — launching the app never reads the secret, so launch never prompts.
- The secret is read only when a request actually needs it. The **first API call from any newly built/signed binary** triggers one macOS Keychain prompt — click **Always Allow** ("Allow" would re-prompt every time). Rebuilding the app or copying it to a new path counts as a new binary.
- **Remove** in Settings deletes the key from the Keychain; the Test Connection and Create buttons disable until a key is saved again.
