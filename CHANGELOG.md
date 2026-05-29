# Changelog

All notable changes to ShieldLock are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2026-05-29

### Fixed
- Lowered the lock window level from `.screenSaver` to `.popUpMenu` so the macOS Touch ID / password fallback dialog renders above the overlay and stays reachable. Previously, choosing "Use Password" from the Touch ID prompt could leave the password sheet trapped behind the overlay, leaving the user unable to authenticate.

### Changed
- Expanded the SSH recovery instructions in the README to call out that Remote Login (System Settings > General > Sharing > Remote Login) must be enabled in advance, and switched the recommended command to `pkill ShieldLock` (SIGTERM) so the app cleans up gracefully before exiting.

## [1.0.3] - 2026-05-29

### Fixed
- Cropped the source logo to a square so the generated `.icns` and the README header no longer appear horizontally squished.

### Changed
- Split the documentation into a user-facing `README.md` and a separate `DEVELOPER.md` for contributors and release maintainers.
- Replaced the OpenGraph social preview banner with an optimized `< 400 KB` JPEG.
- Added a "Disclaimer & No Warranty" section to the README.
- Added Homebrew tap installation instructions (`brew install --cask shieldlock`).

## [1.0.2] - 2026-05-27

### Added
- Real-time Accessibility permission polling: the helper window now detects when the user grants permission in System Settings and automatically transitions into the lock flow without requiring a relaunch.
- High-resolution `.icns` application icon, generated at build time from `docs/logo.png` and bundled into `ShieldLock.app`.

## [1.0.1] - 2026-05-27

### Added
- Confirmation modal on manual launch when ShieldLock is not yet registered as a login item, with a "Launch on login" checkbox to enable seamless boot-time auto-lock.
- `--confirm` command-line flag to force the confirmation modal even when ShieldLock is already registered as a login item (useful for toggling the login-item setting back off).
- Documentation for bypassing macOS Gatekeeper on first launch and for resetting Accessibility permissions after upgrading.

### Changed
- When registered as a login item, ShieldLock now skips the confirmation modal and locks immediately on launch.

### Removed
- Removed the `U` key fail-safe unlock in favor of the double-click + Local Authentication flow.

## [1.0.0] - 2026-05-27

Initial public release.

### Added
- Full-screen transparent overlay across every connected display.
- Global event tap that captures keyboard input and system gestures (Mission Control, app switcher, etc.) while the lock is active.
- Power-management assertions to prevent idle display sleep and idle system sleep while locked.
- Accessibility permission bootstrap window with a "Open System Settings" shortcut.
- Double-click anywhere to trigger Touch ID / password unlock via `LocalAuthentication`.
- Multi-display awareness: lock windows are re-created when screens are added, removed, or rearranged.
- `release.sh` automation script (build, package, tag, GitHub release, Homebrew Cask snippet).
- Emergency recovery documentation covering SSH and Safe Mode.

[1.0.4]: https://github.com/bendechrai/shieldlock/releases/tag/v1.0.4
[1.0.3]: https://github.com/bendechrai/shieldlock/releases/tag/v1.0.3
[1.0.2]: https://github.com/bendechrai/shieldlock/releases/tag/v1.0.2
[1.0.1]: https://github.com/bendechrai/shieldlock/releases/tag/v1.0.1
[1.0.0]: https://github.com/bendechrai/shieldlock/releases/tag/v1.0.0
