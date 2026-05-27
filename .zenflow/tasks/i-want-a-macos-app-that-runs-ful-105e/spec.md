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
  - `ApplicationServices`: For accessibility trust validation (`AXIsProcessTrusted`).
- **Minimum OS Version**: macOS 14.0 (Sonoma) or newer.
- **Build System**: Swift Package Manager (SPM).
- **Packaging**: A lightweight packaging script (`./build.sh`) will bundle the compiled binary into a native macOS app bundle (`./build/ShieldLock.app`) with a configured `./build/ShieldLock.app/Contents/Info.plist` (using `LSUIElement = true` to hide it from the Dock and standard app switchers).

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

### 2.4. Unlocking Mechanisms & Interception Deadlock Avoidance
- **Double-Click Trigger**:
  - The window content view overrides `mouseDown(with:)`. If `event.clickCount == 2`, the local authentication flow is triggered.
- **Authentication Flow (`LocalAuthentication`) & Deadlock Avoidance**:
  - **The Deadlock Challenge**: When Touch ID/Password prompts appear, they are hosted by the system's authentication service. If our high-level `LockWindow` (at `.screenSaver` level) and global `CGEventTap` remain active, they will intercept and consume keyboard and mouse inputs, making it impossible for the user to select the Touch ID dialog or type their password (resulting in a complete input deadlock).
  - **The Safe Authentication Flow**:
    1. **Suspend Interception**: Immediately prior to calling `evaluatePolicy`, the app will:
       - Temporarily disable the event tap: `CGEventTapEnable(tapPort, false)`.
       - Suspend native presentation blocking: `NSApplication.shared.presentationOptions = []`.
       - Configure lock windows to temporarily allow mouse pass-through and lower their level:
         ```swift
         for window in windows {
             window.level = .normal
             window.ignoresMouseEvents = true
         }
         ```
    2. **Trigger Evaluation**:
       - Instantiate `LAContext`.
       - Check `canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)`.
       - Call `evaluatePolicy(_:localizedReason:reply:)` asynchronously. This shows the system Touch ID dialog.
    3. **Resume Interception**: Upon completion of the authentication block (successful, failed, or canceled), the app will dispatch back to the main thread and restore the security state:
       - Restore lock windows:
         ```swift
         for window in windows {
             window.level = .screenSaver
             window.ignoresMouseEvents = false
             window.makeKeyAndOrderFront(nil)
         }
         ```
       - Restore presentation blocking: `NSApplication.shared.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching, ...]`
       - Re-enable the event tap: `CGEventTapEnable(tapPort, true)`.
       - If authentication succeeded, invoke `unlockAndExit()`. If it failed, the lock remains fully active and armed.
- **Fail-Safe 'U' Key**:
  - If a user presses the 'U' key (regardless of upper/lower case) on the keyboard, the app immediately bypasses authentication and performs `unlockAndExit()`. This is a vital fail-safe for the initial MVP to prevent the user from being locked out in case of local authentication bugs.
  - Any other key press will intercept the event, consume it, and briefly flash a visual HUD hint (e.g. "Double-click or press 'U' to unlock").

### 2.5. Accessibility Permissions Bootstrapping & Fallback
On macOS, low-level event taps (`CGEventTap`) require System Accessibility Permissions. If the transparent lock covers the screen on startup before permissions are granted, the user will be deadlocked, unable to click "Allow" in System Settings.

- **Bootstrapping Protocol**:
  1. On startup, the application checks accessibility authorization status:
     ```swift
     let isTrusted = AXIsProcessTrusted()
     ```
  2. **If NOT trusted**:
     - Do **NOT** display the transparent, full-screen `LockWindow` or engage input suppression.
     - Instead, instantiate a standard, interactive macOS App Window (`NSWindowStyleMask.titled`) centered on the primary screen.
     - Display a clean UI message/label: *"ShieldLock requires Accessibility Permissions to secure keyboard events and system gestures. Please grant permissions in System Settings and relaunch the app."*
     - Provide an interactive button: *"Open System Settings"* which executes:
       ```swift
       if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
           NSWorkspace.shared.open(url)
       }
       ```
     - Terminate the application execution or wait for relaunch once settings are configured, preventing any blocking screens from locking the user out.
  3. **If trusted**:
     - Proceed directly to engaging the secure full-screen transparent lock windows and registering the event tap.

---

## 3. Source Code Structure Changes

The following new files will be created in the repository:

- **`./Package.swift`**: Defines the SPM package name, target executables, and dependencies.
- **`./Sources/main.swift`**: Handles accessibility trust validation, standard helper window (if untrusted), `NSApplication` startup, `AppDelegate` lifecycle events, sleep prevention assertions, global presentation options, event tap setup, and the `unlockAndExit` teardown.
- **`./Sources/LockWindow.swift`**: Houses `LockWindow` (subclass of `NSWindow`) and `LockContentView` (subclass of `NSView`) containing the input interceptors, double-click responder, and key-press monitors.
- **`./build.sh`**: A shell script to compile the Swift target, build the `./build/ShieldLock.app` bundle hierarchy, generate `./build/ShieldLock.app/Contents/Info.plist`, and apply an ad-hoc code signature to ensure it runs correctly on Apple Silicon/ARM64 macOS machines:
  ```bash
  codesign --force --deep --sign - ./build/ShieldLock.app
  ```

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
- **Packaging Check**: Execute `./build.sh` to compile in release mode, assemble the bundle, and verify the output structure:
  - `./build/ShieldLock.app`
  - `./build/ShieldLock.app/Contents/MacOS/ShieldLock`
  - `./build/ShieldLock.app/Contents/Info.plist`
- **Code Signing Check**: Verify that the application was successfully signed on Apple Silicon by running:
  ```bash
  codesign -dvvvv ./build/ShieldLock.app
  ```

### 5.2. Functional Testing
1. **Accessibility Bootstrapping Test**:
   - Run `./build/ShieldLock.app` when accessibility permissions are revoked. Verify that the app launches a standard, interactive utility window with a button pointing to System Settings. Verify that no full-screen transparent blocker or input interception engages.
   - Click the button, enable permissions in System Settings, close the app, and relaunch.
2. **Launch & Blocking Test**:
   - On launch with trusted permissions, verify that a fully transparent, full-screen overlay is displayed on all connected monitors, and the Dock and top Menu Bar are completely hidden.
   - Verify that clicking any background application or desktop is blocked.
   - Verify that `Command + Tab` is disabled.
   - Verify that `Command + Option + Esc` does not open the Force Quit window.
   - Verify that swipe gestures do not switch spaces/desktops.
3. **Unlock Verification**:
   - Press the 'U' key on the keyboard: verify the app instantly exits, restoring normal input capabilities, sleep settings, and showing the Dock/Menu Bar.
   - Relaunch the app, double-click anywhere on the transparent overlay: verify the Touch ID / Password sheet appears and the inputs are unlocked *exclusively* for the LocalAuthentication interface. Successfully authenticating must close the lock, while canceling/failing authentication must immediately restore full screen lock levels, inputs, and event tap blocking.
