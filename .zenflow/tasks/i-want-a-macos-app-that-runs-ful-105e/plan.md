# Full SDD workflow

## Configuration
- **Artifacts Path**: {@artifacts_path} → `.zenflow/tasks/{task_id}`

---

## Agent Instructions

---

## Workflow Steps

### [x] Step: Requirements
<!-- chat-id: 3d6b3782-2173-45ba-a312-d060ab5396e2 -->

Create a Product Requirements Document (PRD) based on the feature description.

1. Review existing codebase to understand current architecture and patterns
2. Analyze the feature definition and identify unclear aspects
3. Ask the user for clarifications on aspects that significantly impact scope or user experience
4. Make reasonable decisions for minor details based on context and conventions
5. If user can't clarify, make a decision, state the assumption, and continue

Focus on **what** the feature should do and **why**, not **how** it should be built. Do not include technical implementation details, technology choices, or code-level decisions — those belong in the Technical Specification.

Save the PRD to `{@artifacts_path}/requirements.md`.

### [x] Step: Technical Specification
<!-- chat-id: e992c0d6-c30f-43aa-886d-464a3ef0c98f -->

Create a technical specification based on the PRD in `{@artifacts_path}/requirements.md`.

1. Review existing codebase architecture and identify reusable components
2. Define the implementation approach

Do not include implementation steps, phases, or task breakdowns — those belong in the Planning step.

Save to `{@artifacts_path}/spec.md` with:
- Technical context (language, dependencies)
- Implementation approach referencing existing code patterns
- Source code structure changes
- Data model / API / interface changes
- Verification approach using project lint/test commands

### [x] Step: Planning
<!-- chat-id: 281afbd3-fec4-41ed-abaf-70f3f40a56e1 -->

Create a detailed implementation plan based on `{@artifacts_path}/spec.md`.

1. Break down the work into concrete tasks
2. Each task should reference relevant contracts and include verification steps
3. Replace the Implementation step below with the planned tasks

Rule of thumb for step size: each step should represent a coherent unit of work (e.g., implement a component, add an API endpoint). Avoid steps that are too granular (single function) or too broad (entire feature).

Important: unit tests must be part of each implementation task, not separate tasks. Each task should implement the code and its tests together, if relevant.

If the feature is trivial and doesn't warrant full specification, update this workflow to remove unnecessary steps and explain the reasoning to the user.

Save to `{@artifacts_path}/plan.md`.

### [x] Step: Setup SPM and Build Scaffolding
<!-- chat-id: 43d0f368-c551-4e76-8358-fb7060e60da4 -->
- Create `.gitignore` to ignore common macOS and build artifacts (e.g., `.DS_Store`, `.build/`, `build/`).
- Create `Package.swift` to declare a Swift executable target named `ShieldLock`.
- Create target directory `Sources/`.
- Create a basic `Sources/main.swift` with an empty main function.
- Create `./build.sh` script to:
  - Run `swift build -c release` to compile the app.
  - Create the bundle directory structure: `./build/ShieldLock.app/Contents/MacOS/` and `./build/ShieldLock.app/Contents/Resources/`.
  - Copy the compiled binary from `.build/release/ShieldLock` to `./build/ShieldLock.app/Contents/MacOS/ShieldLock`.
  - Generate the `./build/ShieldLock.app/Contents/Info.plist` with `LSUIElement` set to `true` (to run as an accessory/background app), `CFBundlePackageType` set to `APPL`, and include the `NSFaceIDUsageDescription` entitlement key with a descriptive description string to grant Face ID/Touch ID biometrics permission.
  - Sign the bundle with ad-hoc code signature: `codesign --force --deep --sign - ./build/ShieldLock.app`.
- **Verification**: Run `./build.sh`, verify it completes successfully, and verify the app bundle is compiled, structured correctly, and signed with `codesign -dvvvv ./build/ShieldLock.app`.

### [x] Step: Accessibility Bootstrapping and Help Window
<!-- chat-id: 200f1ea5-565e-47ad-99f7-b8178dc9520a -->
- In `Sources/main.swift`, check if accessibility permissions are authorized using `AXIsProcessTrusted()`.
- If permissions are NOT trusted:
  - Create and configure a standard interactive titled window (`NSWindowStyleMask.titled`) centered on the primary screen.
  - Add text label instructions explaining that ShieldLock requires Accessibility Permissions to secure the keyboard/gestures, and directing the user to grant them.
  - Add an interactive button labeled "Open System Settings" that opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
  - Run the `NSApplication` event loop in this fallback state (do not engage full-screen lock windows).
- If permissions ARE trusted:
  - In `AppDelegate.applicationDidFinishLaunching`, attempt to register the application as a persistent login item using the native `SMAppService.mainApp.register()` API to ensure the app starts on user login.
  - Run the app in background/accessory mode.
- **Verification**:
  - Revoke accessibility permissions in System Settings (if any) or run the app on a fresh target. Launch `./build/ShieldLock.app` and verify the titled helper window appears with the "Open System Settings" button.
  - Click the button to confirm it opens System Settings.
  - Enable accessibility permissions for the app, relaunch, and verify the standard window does not appear and that the app successfully registers itself as a Login Item under System Settings.

### [x] Step: Full-Screen Lock Windows and Sleep Prevention
<!-- chat-id: 243221fe-9423-4adc-8204-c32a4f014f20 -->
- Implement `LockWindow` (subclass of `NSWindow`) and `LockContentView` (subclass of `NSView`) in a new file `Sources/LockWindow.swift`.
- In `main.swift` (when trusted), query `NSScreen.screens` and create a `LockWindow` instance for every connected display.
- Configure `LockWindow` properties:
  - Elevated window level: `NSWindow.Level.screenSaver`.
  - Style mask: `[.borderless, .fullScreen]`.
  - Collection behavior: `[.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]` to pin the window to all Spaces and exclude it from window cycling.
  - Background color: `NSColor(white: 0.0, alpha: 0.005)` to capture mouse events while remaining transparent.
  - Set `ignoresMouseEvents = false` and ensure the window is ordered front (`makeKeyAndOrderFront(nil)`).
- Implement Dynamic Screen Layout Handling: Subscribe to `NSApplication.didChangeScreenParametersNotification` in `main.swift` to dynamically destroy existing lock windows and recreate fresh lock windows covering all screens whenever display configurations or screen resolutions change.
- Implement display and system sleep prevention on launch using `IOPMAssertionCreateWithName` from `IOKit` with type `kIOPMAssertionTypePreventUserIdleDisplaySleep` and `kIOPMAssertionTypePreventUserIdleSystemSleep`.
- Release assertions and clean up windows on application termination.
- **Verification**:
  - Run `./build.sh` and launch the app.
  - Verify that a fully transparent screen overlay is rendered across all displays (the screen looks normal but clicks on any background windows/desktop are intercepted and ignored).
  - Verify that plugging in/unplugging displays or changing resolutions dynamically recreates lock windows on all active screens with no unprotected gaps.
  - Verify that the terminal process/system remains awake.

### [ ] Step: Input Interception and System Event Tap
- In `main.swift`, set native AppKit presentation options when lock windows are active to restrict system keys and switching:
  ```swift
  NSApplication.shared.presentationOptions = [
      .hideDock,
      .hideMenuBar,
      .disableProcessSwitching,
      .disableForceQuit,
      .disableSessionTermination,
      .disableHideApplication
  ]
  ```
- Implement a global event tap (`CGEventTap`) using `CGEvent.tapCreate` targeting `.cgSessionEventTap` or `.cghidEventTap` to intercept and consume system gestures, Mission Control (F3), Dashboard/Launchpad (F4), Spotlight (Command-Space), and standard desktop/Space switching swipes.
- If accessibility permissions are not granted (though bootstrapping should have caught this), let the event tap fail gracefully and fallback to presentation options.
- Ensure all intercepted keystrokes (except the fail-safe trigger) and clicks are consumed (discarded) by the event tap and main window.
- **Verification**:
  - Launch ShieldLock with accessibility permissions enabled.
  - Verify the Dock and Menu Bar are hidden.
  - Test and verify that Command-Tab (App Switcher), Command-Option-Esc (Force Quit), and Mission Control are completely blocked.
  - Verify that trackpad swipe gestures to change Spaces are completely non-functional.

### [ ] Step: Authentication Flow and Fail-Safe Unlock
- In `LockContentView`, monitor keyboard input events:
  - If the user presses the 'U' (or 'u') key, instantly bypass authentication and invoke the `unlockAndExit()` routine to dismiss windows, release sleep assertions, and terminate.
  - For other key presses, consume the event and show a brief HUD/visual hint ("Double-click or press 'U' to unlock").
- In `LockContentView`, monitor mouse/trackpad events:
  - Detect double-clicks (`event.clickCount == 2`). On double-click, trigger the `LocalAuthentication` flow.
- Implement secure authentication handling using `LAContext` to prevent deadlocks and ensure continuous security:
  1. Temporarily disable only the global event tap (`CGEventTapEnable(tapPort, false)`) to prevent interception of inputs aimed at the OS authentication prompt.
  2. **Do NOT lower lock windows levels to `.normal` or set `ignoresMouseEvents = true` or disable AppKit kiosk presentation options**. The overlay windows must remain at `.screenSaver` level and active to consume any background interactions and prevent unauthorized bypass. The system Touch ID/Password dialog displays automatically above all standard application windows and receives secure input safely.
  3. Perform `LAContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock ShieldLock")`.
  4. On callback completion (success, cancellation, or failure):
     - Re-enable the global event tap (`CGEventTapEnable(tapPort, true)`).
     - If authentication succeeded, call `unlockAndExit()`. If failed/canceled, keep the overlay locked and armed.
- **Verification**:
  - Launch ShieldLock. Verify that pressing 'U' (or 'u') immediately exits the app and restores all normal system behaviors.
  - Relaunch ShieldLock. Double-click on the screen. Verify that the Touch ID / Password prompt dialog is presented.
  - Verify that during the prompt, background windows are completely non-interactive and secure against any bypass attempts.
  - Verify that clicking "Cancel" in the prompt re-locks the screen immediately, re-enabling the event tap.
  - Verify that authenticating successfully exits the app cleanly.
