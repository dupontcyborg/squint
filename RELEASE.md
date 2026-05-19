# Release Guide

This guide outlines the step-by-step process of signing, notarizing, and packaging Squint for public distribution outside of the Mac App Store.

## Prerequisites

To sign and notarize Squint, you must have:
1. An active **Apple Developer Account** ($99/year).
2. A **Developer ID Application** certificate installed in your macOS Keychain.
3. An **App-Specific Password** generated on your [Apple ID account page](https://appleid.apple.com/) to authenticate with Apple's notarization servers.
4. Set up a local keychain profile for Apple's `notarytool` by running:
   ```bash
   xcrun notarytool store-credentials "AC_PASSWORD" --apple-id "your-apple-id@email.com" --team-id "YOURTEAMID" --password "abcd-efgh-ijkl-mnop"
   ```
   *(Replace with your actual Apple ID, Team ID, and the generated App-Specific Password).*

## Release Process

### 1. Tag the Release
We use Git tags to configure the version number of the app.
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
```

### 2. Compile and Package the Bundle
Run the local build script. This will compile the code and inject the version tag (`1.0.0`) into the app bundle's `Info.plist`:
```bash
./build.sh
```

### 3. Code Sign the `.app` Bundle
Code sign the app bundle with the Hardened Runtime enabled. Replace `"Developer ID Application: Your Name (TEAMID)"` with your exact certificate common name from Keychain Access:
```bash
codesign --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" build/Squint.app
```

Verify that the signature is valid and has the hardened runtime enabled:
```bash
codesign --verify --deep --strict --verbose=2 build/Squint.app
```

### 4. Create the DMG Package
Create the drag-and-drop installer disk image:
```bash
./create_dmg.sh
```
This outputs a file named `Squint-1.0.0.dmg` in the repository root.

### 5. Sign the DMG
We also need to sign the DMG container itself:
```bash
codesign --force --sign "Developer ID Application: Your Name (TEAMID)" Squint-1.0.0.dmg
```

### 6. Submit to Apple for Notarization
Submit the signed DMG to Apple's notarization service using the credentials profile we stored in the prerequisites:
```bash
xcrun notarytool submit Squint-1.0.0.dmg --keychain-profile "AC_PASSWORD" --wait
```
This upload takes a moment and will wait for Apple's automated checks to complete (usually ~1 minute). If successful, you will see a `Status: Accepted` confirmation.

### 7. Staple the Notarization Ticket
Staple the notarization ticket to the DMG file so Gatekeeper can verify it offline when the user downloads it:
```bash
xcrun stapler staple Squint-1.0.0.dmg
```

Verify that the stapled ticket is active:
```bash
spctl --assess --type open --context context:primary-signature --verbose Squint-1.0.0.dmg
```

## 8. Publish on GitHub

1. Push your tag to GitHub: `git push origin v1.0.0`.
2. Go to your repository's Releases page, create a new release from the `v1.0.0` tag, and upload `Squint-1.0.0.dmg` as an asset.
3. Users can now download and open the DMG without any Gatekeeper developer verification warnings.
