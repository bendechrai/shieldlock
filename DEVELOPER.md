# ShieldLock Developer Documentation

This document contains information for developers who want to contribute to ShieldLock, build it from source, or manage releases.

## Project Structure

- `./Package.swift`: Swift Package Manager configuration.
- `./Sources/main.swift`: Entry point, AppDelegate, Event Tap configuration, and sleep prevention.
- `./Sources/LockWindow.swift`: Custom full-screen window and view implementations, HUD presentation, and Local Authentication handling.
- `./build.sh`: Custom build script to compile the application and construct the macOS application bundle.

## Building and Packaging

Run the custom build script to compile the executable and generate the code-signed application bundle `./build/ShieldLock.app`:

```bash
./build.sh
```

The script will compile the project in release mode, structure the bundle with proper `Info.plist` settings (including accessory mode and Face ID usage descriptions), and code-sign it.

## Code Signing

ShieldLock is signed with a self-signed code-signing certificate so that macOS Accessibility (TCC) permissions persist across upgrades. With ad-hoc signing (`codesign --sign -`), every build has a different code identity, so macOS treats each upgrade as a new app and silently invalidates the previously granted Accessibility permission. A stable self-signed identity fixes that.

`build.sh` looks up a code-signing identity by name. It uses the value of the `SHIELDLOCK_SIGN_IDENTITY` environment variable, or `ShieldLock Developer` if that variable is unset. If the identity is found in your keychain, the bundle is signed with it. If not, the script falls back to ad-hoc signing so contributors without the cert can still build locally - but those builds will not preserve Accessibility permissions across upgrades.

### One-Time Cert Setup (Release Maintainer)

Do this once on the machine you cut releases from:

1. Open **Keychain Access** (`open /System/Applications/Utilities/Keychain\ Access.app`).
2. Menu: **Keychain Access > Certificate Assistant > Create a Certificate...**
3. Fill in:
   - **Name**: `ShieldLock Developer` (this exact string is what `build.sh` looks for; override with `SHIELDLOCK_SIGN_IDENTITY` if you want a different label).
   - **Identity Type**: `Self Signed Root`
   - **Certificate Type**: `Code Signing`
4. Click **Create**, accept the warning, then **Done**. The cert and its private key land in your `login` keychain.
5. Trust the cert for code signing: in Keychain Access, double-click the new `ShieldLock Developer` cert, expand the **Trust** disclosure triangle, and set **Code Signing** to **Always Trust**. Close the window and enter your login password when prompted to save.

Verify it's wired up:

```bash
security find-identity -v -p codesigning
```

You should see one valid identity listed as `ShieldLock Developer`. If you don't, the cert isn't trusted, isn't in your `login` keychain, or your keychain search list doesn't include `login.keychain-db` (see the SSH note below).

### Important: Keep the Private Key Safe

The private key for the `ShieldLock Developer` cert is the trust anchor for every ShieldLock release. If it is lost (disk failure, account reset, etc.), the next release will be signed with a *new* identity and existing users' Accessibility permissions will be silently invalidated on upgrade - the same one-time pain the `1.0.4` to `1.0.5` upgrade caused for users.

Back the cert up by exporting it from Keychain Access (`File > Export Items...` while the cert is selected, save as a `.p12` with a strong password, store somewhere safe and offline). Import the same `.p12` if you ever need to release from a different Mac.

## Releasing to GitHub and Homebrew Cask

An automated release script `./release.sh` is provided to streamline the manual distribution workflow:

```bash
./release.sh
```

This script will:
1. Prompt you for a release version (e.g., `1.0.0`).
2. Verify your git working directory is clean.
3. Compile the application locally (using your `ShieldLock Developer` cert if available, ad-hoc otherwise).
4. Package the signed app bundle into a `ShieldLock.zip`.
5. Compute the required SHA256 checksum for your Homebrew Cask.
6. Create and push a version tag (e.g., `v1.0.0`) to your GitHub repository.
7. Create a GitHub Release and upload `ShieldLock.zip` using the `gh` CLI.
8. Output the ready-to-use Homebrew Cask configuration block with the updated version, download URL, and SHA256 checksum.

### Releases Must Be Cut from a Local Console Session

macOS keychain access is bound to the launchd "security session" of the calling process. The login session you get when you sit at the Mac (or connect via Screen Sharing / VNC) can read the `login` keychain; an `ssh` session gets a separate, non-graphical security session that cannot, even when the keychain is unlocked. Symptoms of trying to run `release.sh` over SSH:

- `security list-keychains` shows only `/Library/Keychains/System.keychain`.
- `security find-identity -v -p codesigning` returns `0 valid identities found`.
- `codesign` reports `ShieldLock Developer: no identity found`.
- `security list-keychains -s ...` and `--keychain` on `codesign` both silently fail to fix it.

`launchctl asuser` can attach SSH commands to your GUI session but it requires `sudo` and is brittle. The reliable workflow is to cut releases from a local Terminal session:

1. Sit at the Mac, **or** connect to it from another machine via **System Settings > General > Sharing > Screen Sharing** (enable it ahead of time if you haven't).
2. Open `Terminal.app` in the GUI session.
3. `cd` to the repo and run `./release.sh`. Enter the new version when prompted.
4. The script signs with `ShieldLock Developer`, tags, pushes, and creates the GitHub release.
5. Note the SHA256 it prints - you'll need it for the homebrew-tap bump.

Everything *else* (editing code, committing, updating the cask, pushing to GitHub) is fine over SSH. Only the codesign step in `release.sh` requires the GUI security session.
