# Technical Specification: Transparent macOS Input Lock (ShieldLock)

This document outlines the technical specification and architecture for **ShieldLock**, a lightweight, secure macOS utility that covers all screens with a fully transparent overlay, intercepting and consuming all input events to prevent unauthorized system interaction. It integrates with macOS LocalAuthentication for Biometrics/Password unlocking, prevents system/display sleep, and natively suppresses system shortcuts (like Command-Tab, Force Quit, and Mission Control).

---

## 1. Technical Context

- **Language**: Swift 6 (utilizing modern concurrency and AppKit integration)
- **Frameworks**:
  - `AppKit`: Native Cocoa UI library for window creation, presentation configuration, and window-level manipulation.
  - `LocalAuthentication`: Native framework for Touch ID biometric validation and secure admin password fallbacks.
  - `IOKit (Power Management)`: Prevents the display and system from going to sleep while locked.
  - `CoreGraphics`: Low-level system event tap (`CGEventTap`) for advanced keyboard and gesture intercepting.
- **Minimum OS Version**: macOS 14.0 (Sonoma) or newer.
- **Build System**: Swift Package Manager (SPM).
- **Packaging**: A lightweight packaging script (`./build.sh`) will bundle the compiled binary into a native macOS app bundle (`ShieldLock.app`) with a configured `./Contents/Info.plist` (using `LSUIElement = true` to hide it from the Dock and standard app switchers).

---

## 2. Implementation Approach

### 2.1. App Lifecycle & Architecture
The application runs as a background accessory app (`LSUIElement` / `.accessory` activation policy). This ensures there is no standard macOS menu bar, and no Dock icon that can be right-clicked to quit the app.

- **Entry Point (`./Sources/main.swift`)**:
  - Instantiates `NSApplication.shared`.
  - Sets the application delegate to a custom `AppDelegate`.
  - Sets activation policy to `.accessory`.
  - Runs the main event loop.

- **Power Management (Sleep Prevention)**:
  - On launch, the app uses `IOPMAssertionCreateWithName` from `IOKit` to request `kIOPMAssertionTypePreventUserIdleDisplaySleep` and `kIOPMAssertionTypePreventUserIdleSystemSleep`. This guarantees that the MacBook stays awake and the screen stays on, always displaying the running servers / background slide decks.
  - Assertions are safely released when the app is unlocked or terminates.

### 2.2. Windowing Architecture (`./Sources/LockWindow.swift`)
To protect against multi-monitor setups and prevent any gaps, the app queries `NSScreen.screens` on launch and creates an independent full-screen overlay window (`LockWindow`) for every active display.

- **Window Configurations**:
  - **Level**: `NSWindow.Level.screenSaver` (or an elevated custom level equivalent to `CGShieldingWindowLevel()`). This positions the window on top of the Dock, the macOS top Menu Bar, standard applications, and dialog boxes.
  - **Collection Behavior**: `[.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`. This pins the overlay to all virtual desktops (Spaces), preventing Mission Control or gesture swipes from moving the lock window off-screen.
  - **Visuals**:
    - `styleMask = [.borderless, .fullScreen]`
    - `backgroundColor = NSColor(white: 0.0, alpha: 0.005)` (A tiny, imperceptible alpha value ensures macOS routes all mouse clicks to our window instead of treating it as an empty pass-through, while remaining completely invisible to the human eye).
    - `isOpaque = false`
    - `hasShadow = false`
    - `ignoresMouseEvents = false` (Captures mouse clicks, hover, scroll wheel).

### 2.3. Input Interception & Suppression
To completely secure the machine, ShieldLock uses a dual-layer interception approach:

1. **System Presentation Options (Built-in AppKit Lock)**:
   - When the lock window becomes key and active, the app sets:
     ```swift
     NSApplication.shared.presentationOptions = [
         .hideDock,
         .hideMenuBar,
         .disableProcessSwitching, // Blocks Command-Tab / Command-Esc
         .disableForceQuit,         // Blocks Command-Option-Esc (Force Quit)
         .disableSessionTermination,// Blocks Command-Power-button / Logout
         .disableHideApplication    // Blocks Command-H
     ]
     ```
   - This native AppKit kiosk mode is highly secure and runs out of the box without requiring specialized system accessibility permissions.

2. **Global Input Interception (`CGEventTap`)**:
   - To intercept trackpad swipe gestures, Mission Control (F3), Dashboard/Launchpad (F4), and Spotlight (Command-Space), the app attempts to register a local/global event tap using `CGEvent.tapCreate` targeting `.cgSessionEventTap` or `.cghidEventTap`.
   - If Accessibility permissions are not yet granted, the event tap setup fails gracefully, falling back to the AppKit Presentation Options, which still fully block the Dock, Menu Bar, Command-Tab, and Force Quit.

### 2.4. Unlocking Mechanisms & Fail-Safe
- **Double-Click Trigger**:
  - The window content view overrides `mouseDown(with:)`. If `event.clickCount == 2`, the local authentication flow is triggered.
- **Authentication Flow (`LocalAuthentication`)**:
  - Instantiates `LAContext`.
  - Checks `canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)`.
  - Evaluates the policy using `evaluatePolicy(_:localizedReason:reply:)`. This triggers the system Touch ID prompt.
  - If Touch ID is unavailable or fails, it falls back to the administrator's password prompt.
  - Upon successful authentication, the overlay calls `unlockAndExit()`, releasing sleep assertions, closing windows, and terminating the application.
- **Fail-Safe 'U' Key**:
  - If a user presses the 'U' key (regardless of upper/lower case) on the keyboard, the app immediately bypasses authentication and performs `unlockAndExit()`. This is a vital fail-safe for the initial MVP to prevent the user from being locked out in case of local authentication bugs.
  - Any other key press will intercept the event, consume it, and briefly flash a visual HUD hint (e.g. "Double-click or press 'U' to unlock").

---

## 3. Source Code Structure Changes

The following new files will be created in the repository:

- **`./Package.swift`**: Defines the SPM package name, target executables, and dependencies.
- **`./Sources/main.swift`**: Handles `NSApplication` startup, `AppDelegate` lifecycle events, sleep prevention assertions, global presentation options, event tap setup, and the `unlockAndExit` teardown.
- **`./Sources/LockWindow.swift`**: Houses `LockWindow` (subclass of `NSWindow`) and `LockContentView` (subclass of `NSView`) containing the input interceptors, double-click responder, and key-press monitors.
- **`./build.sh`**: A shell script to compile the Swift target, build the `.app` bundle hierarchy, and generate `./Contents/Info.plist`.

---

## 4. Interface & State Design

### 4.1. Application State
Purely in-memory runtime variables managed by the `AppDelegate`:
- **`windows: [LockWindow]`**: Array of active lock windows, one for each connected display.
- **`sleepAssertionID: IOPMAssertionID`**: Unique ID of the active display sleep prevention assertion.
- **`eventTapPort: CFMachPort?`**: Low-level reference to the event tap.
- **`runLoopSource: CFRunLoopSource?`**: Runloop source for the event tap thread.

---

## 5. Verification & Testing Approach

Since Xcode IDE is not installed, validation will be performed using Swift CLI and testing commands.

### 5.1. Build and Pack Verification
- **Compilation Check**: Run `swift build` to ensure the project compiles without warnings or errors.
- **Packaging Check**: Execute `./build.sh` to compile in release mode and verify the output bundle structure:
  - `./build/ShieldLock.app`
  - `./build/ShieldLock.app/Contents/MacOS/ShieldLock`
  - `./build/ShieldLock.app/Contents/Info.plist`

### 5.2. Functional Testing
1. **Launch Test**: Start the compiled app bundle and verify:
   - A fully transparent, full-screen overlay is displayed on all connected monitors.
   - The Dock and top Menu Bar are completely hidden.
2. **Blocking Test**:
   - Verify that clicking any background application or desktop is blocked.
   - Verify that `Command + Tab` is disabled.
   - Verify that `Command + Option + Esc` does not open the Force Quit window.
   - Verify that swipe gestures do not switch spaces/desktops.
3. **Unlock Verification**:
   - Press the 'U' key on the keyboard: verify the app instantly exits, restoring normal input capabilities, sleep settings, and showing the Dock/Menu Bar.
   - Relaunch the app, double-click anywhere on the transparent overlay: verify the Touch ID / Password sheet appears. Successfully authenticating must close the lock, while canceling/failing authentication must leave the lock active.
