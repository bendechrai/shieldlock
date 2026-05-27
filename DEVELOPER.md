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

## Releasing to GitHub and Homebrew Cask

An automated release script `./release.sh` is provided to streamline the manual distribution workflow:

```bash
./release.sh
```

This script will:
1. Prompt you for a release version (e.g., `1.0.0`).
2. Verify your git working directory is clean.
3. Compile the application locally.
4. Package the secure app bundle into a `ShieldLock.zip`.
5. Compute the required SHA256 checksum for your Homebrew Cask.
6. Create and push a version tag (e.g., `v1.0.0`) to your GitHub repository.
7. Create a GitHub Release and upload `ShieldLock.zip` using the `gh` CLI.
8. Output the ready-to-use Homebrew Cask configuration block with the updated version, download URL, and SHA256 checksum!
