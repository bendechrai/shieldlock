# Product Requirements Document (PRD): Transparent macOS Input Lock (ShieldLock)

## 1. Overview and Goal
The objective is to create a secure, lightweight macOS utility application that acts as a full-screen, fully transparent "input overlay shield". It runs in full-screen mode, prevents unauthorized access, application switching, and keyboard/mouse interaction with background programs, while allowing everything currently on the screen to remain completely visible. Unlocking the overlay requires the macOS user account password, Touch ID, or a temporary fail-safe bypass (pressing the 'U' key).

This utility prevents casual use of an unlocked laptop (e.g., a MacBook Air server running Hermers AI / dev sites, or a work laptop at an exhibition booth running a slide deck) by blocking inputs and system controls, while still allowing viewers to see everything displayed on the screen.

---

## 2. Core Use Case
- **Public/Always-On Presentation and System Protection**: 
  - The laptop is logged in, active, and runs background applications (such as a slideshow presentation, terminal monitoring, or local servers).
  - The system must NOT sleep, go black, or show the macOS screen saver/lock screen.
  - The ShieldLock application is active and transparent. A viewer can see the screen clearly, but if they try to click, gesture, or press keys to interact with the background apps or switch windows, they are completely blocked.
  - Only authorized users can interact with the machine or close the overlay by authenticating (via Touch ID / Password) or pressing the temporary fail-safe 'U' key (MVP feature).

---

## 3. Functional Requirements

### 3.1. Secure Transparent Overlay Window
- **Full-Screen Coverage**: The application window must cover the entire screen area (and dynamically cover all connected displays if multiple monitors are used). It must reside at an elevated window level (e.g., above the menu bar, Dock, and other application windows) to serve as a complete shield.
- **Pure Transparency**: The overlay window must be fully transparent, allowing absolute visibility of the windows, slideshows, or applications running underneath.
- **Input Interception**: The overlay window must capture and consume all mouse events (clicks, scrolls, drags, hovering) and keyboard events, preventing any underlying applications from receiving them.
- **Inhibit Sleep**: The application must inhibit system and display sleep (keeping the screen on and awake continuously) while the lock is active.

### 3.2. System Event & Gesture Blocking
- **App Switching Restriction**: The application must block the user from switching focus to other apps or using OS controls:
  - Command + Tab (Application Switcher)
  - Mission Control / Expose (F3 key, gesture swipes)
  - Spotlight (Command + Space)
  - Dock, Launchpad, Notification Center, Siri
  - Swipe gestures for switching desktops/full-screen spaces
- **Termination/Bypass Prevention**: 
  - The application must intercept and disable system logout/lock shortcuts like Command + Shift + Q and other shortcuts that would trigger native OS lock screens or sleep, as these could be used to bypass the app or disrupt the display.
  - Standard termination shortcuts (e.g., Command + Q) must be intercepted and ignored.

### 3.3. Authentication & Unlocking
- **Local Authentication Integration**: The application leverages the macOS `LocalAuthentication` framework to verify identity.
- **Unlock Triggers**:
  - Double-clicking the overlay window, pressing a shortcut key, or clicking a trigger initiates the unlock sequence.
- **Touch ID & Password Support**:
  - The application triggers a prompt for Touch ID biometric verification.
  - If Touch ID is unavailable or bypassed, the standard system password prompt sheet is displayed as fallback.
- **Fail-Safe 'U' Key (MVP)**:
  - For the first MVP, pressing the 'U' key on the keyboard will also immediately unlock and dismiss the overlay. This provides a crucial fail-safe if there are issues with local authentication or input interception.
- **Lock Dismissal**:
  - Upon successful verification (or pressing 'U'), the transparent overlay window is dismissed (closed/hidden).
  - Upon failure, the overlay remains active and locked.

### 3.4. Launch and Behavior
- **Lock on Launch**: Launching the application immediately engages the full-screen transparent lock. It does NOT trigger the native macOS OS-level screen lock, but acts as its own secure input barrier.

---

## 4. Non-Functional Requirements
- **Security & Integrity**: The overlay must prevent casual bypass through keyboard layouts or standard gestures.
- **Resource Efficiency**: Negligible CPU and memory utilization since it remains active 24/7 on always-on displays.
- **Display Adaptability**: Dynamically resizes/re-creates the transparent window to adapt to resolution changes, screen waking, or plugging/unplugging external monitors.
- **Native Implementation**: Developed using native macOS Swift/Objective-C to interact reliably with low-level Cocoa/AppKit window level APIs and event taps.

---

## 5. Future Roadmap / Out-of-Scope Features
- **Bluetooth Proximity Unlock**: Automatically lock/unlock based on proximity of trusted devices.
- **Mobile Companion App**: Remote control capabilities.
