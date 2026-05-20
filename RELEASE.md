# Release Guide

Releases are automated via [`.github/workflows/release.yml`](.github/workflows/release.yml). Pushing a `v*` tag builds, signs, notarizes, and publishes a pre-release; a manual approval then promotes it to stable and opens a PR updating the Sparkle appcast.

## One-Time Setup

### Apple credentials (repository secrets)
Set the following under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `MACOS_CERTIFICATE_BASE64` | Developer ID Application `.p12` certificate, base64-encoded (`base64 -i cert.p12`) |
| `MACOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `DEVELOPER_ID_NAME` | Common name of the cert, e.g. `Your Name (TEAMID)` |
| `APPLE_ID` | Apple ID email used for notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) |
| `APPLE_TEAM_ID` | 10-character Apple Team ID |
| `SPARKLE_PRIVATE_KEY_BASE64` | EdDSA private key (PEM) from Sparkle's `generate_keys`, base64-encoded (`base64 -i sparkle_private.pem`) |

The matching `SPARKLE_PUBLIC_KEY` must be set as `SUPublicEDKey` in `Squint/Info.plist`.

### Production environment
Create a GitHub environment named `production` with required reviewers — this gates the promotion step.

## Cutting a Release

1. **Add the changelog entry.** Append the new version to [`changelog.yml`](changelog.yml):
   ```yaml
   v1.0.0:
     title: "Short release headline"
     notes: |
       - First change.
       - Second change.
   ```
   The workflow will fail fast at the validation step if the pushed tag has no matching entry.

2. **Tag and push.**
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

3. **Watch the build.** The `build` job will:
   - Validate the changelog entry.
   - Import the signing certificate into a temporary keychain.
   - Run `./build.sh`, then sign Sparkle's nested helpers (XPCs, `Autoupdate`, `Updater.app`) and the app, in order.
   - Submit to Apple's notary service via `notarytool`, staple, and `spctl`-verify.
   - Build `Squint.dmg`, codesign it, and produce its Sparkle EdDSA signature.

4. **Pre-release is published automatically** on the GitHub Releases page. Smoke-test the DMG locally.

5. **Approve the production promotion.** The `approve-and-publish` job is gated on the `production` environment. An approver in GitHub Actions UI clicks **Review deployments → Approve**. This:
   - Flips the release from pre-release to latest stable.
   - Runs `scripts/update_appcast.py` to append the new `<item>` to `website/public/appcast.xml`.
   - Bumps `website/package.json` (and `package-lock.json`) so the landing page's download button reflects the new version.
   - Opens a PR `release/appcast-vX.Y.Z` against `main`. Merge it to ship the update to Sparkle clients and the website (Cloudflare Pages rebuilds the site on merge).

## Local Build (Debugging Only)

For reproducing failures or testing the bundle without cutting a release:

```bash
./build.sh                                                    # → build/Squint.app
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" build/Squint.app
codesign --verify --deep --strict --verbose=2 build/Squint.app
./create_dmg.sh                                               # → Squint-X.Y.Z.dmg
codesign --force --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" Squint-X.Y.Z.dmg
xcrun notarytool submit Squint-X.Y.Z.dmg --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple Squint-X.Y.Z.dmg
spctl --assess --type open --context context:primary-signature --verbose Squint-X.Y.Z.dmg
```

The `AC_PASSWORD` keychain profile is created once with:
```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "you@example.com" --team-id "TEAMID" --password "xxxx-xxxx-xxxx-xxxx"
```

Do **not** use a local build for production distribution — the CI flow is the source of truth for signing, signature consistency, and appcast publication.
