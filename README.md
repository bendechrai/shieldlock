# ShieldLock

ShieldLock is an open-source, full-screen transparent screen locker for macOS. It is designed for always-on servers (like a MacBook Air server) or presentation/booth laptops where you want the screen content to remain visible, but want to prevent unauthorized application switching, desktop swipes, or system gestures.

## Features

- **Transparent Screen Overlay**: Recreates secure full-screen transparent windows across all connected displays.
- **Input & Gesture Interception**: Utilizes a low-level Event Tap to block Spotlight, Command-Tab, Mission Control, Launchpad, and trackpad swipe gestures.
- **Sleep Prevention**: Disables user idle system and display sleep automatically while active.
- **Secure Authentication**: Supports secure biometrics (Touch ID) or macOS system password using Local Authentication (`LAContext`).
- **Fail-Safe Unlock**: Provides a quick development or administrative override by pressing the `U` key.
- **Accessibility Bootstrapping**: Detects permissions on launch and displays a helper window directing the user to System Settings if Accessibility permissions are missing.

## Prerequisites

- macOS 13.0 or later
- Swift 5.8 or later
- Accessibility permissions granted to the application (the app will prompt you with instructions on launch)

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

## Running ShieldLock

Start the application with:

```bash
open ./build/ShieldLock.app
```

On first launch, if Accessibility permissions have not been granted, a helper window will appear with a button to open System Settings directly. Once granted, relaunch ShieldLock to secure the system.

## Unlocking ShieldLock

There are two ways to unlock and close the app:

1. **Secure Biometrics/Password**: Double-click anywhere on any screen to trigger the macOS Local Authentication dialog (Touch ID or user password). During authentication, the transparent overlay remains at `.screenSaver` window level to keep background content secure.
2. **Fail-Safe**: Press the `U` (or `u`) key on the keyboard to instantly bypass authentication and exit ShieldLock.

### Emergency Recovery / Locked Out?

If you are completely locked out of the GUI (e.g. keyboard is not registering input or the unlock key fails):

1. **Via SSH (Remote Recovery)**:
   - SSH into the machine from another device on your network and terminate the ShieldLock process:
     ```bash
     killall ShieldLock
     ```
     This will instantly dismiss all lock windows, release the event tap, restore standard system presentation options (Dock and Menu Bar), and terminate the application safely.

2. **Via Safe Mode (Local Recovery)**:
   - If you cannot SSH in, force-restart your Mac and boot into **Safe Mode**:
     - **Apple Silicon (M1/M2/M3)**: Shut down your Mac. Press and hold the power button until you see "Loading startup options". Select your startup disk, then press and hold the **Shift** key and click **Continue in Safe Mode**.
     - **Intel Mac**: Restart your Mac and immediately press and hold the **Shift** key until you see the login window.
   - Safe Mode prevents third-party Login Items (including ShieldLock) from launching automatically.
   - Once logged in, go to **System Settings > General > Login Items** and remove ShieldLock, or delete the `ShieldLock.app` bundle to disable it.

## License

This project is licensed under the MIT License - see `./LICENSE` for details.
