# Product Requirements Document (PRD): Transparent macOS Screen Lock (ShieldLock)

## 1. Overview and Goal
The objective is to create a secure, lightweight macOS utility application that acts as a full-screen "screen lock" or "overlay shield". It runs in full-screen mode, prevents unauthorized access, application switching, and keyboard/mouse interaction with background programs, while allowing the user to choose whether background content (such as presentations, slideshows, or status monitors) remains visible or is obscured by an opaque color. Unlocking the overlay requires the macOS user account password or Touch ID.

This utility is designed for two main scenarios:
1. **Always-On Servers / Displays**: An always-on, auto-login MacBook Air server running Hermes AI and local development sites. The screen should be protected from interaction but still visible or cleanly covered.
2. **Exhibition Booth Laptops**: A work laptop at a trade show booth showing a slide deck or demo. The screen can be unlocked/viewed by visitors, but nobody can switch applications (Cmd+Tab, Mission Control, gestures), access the finder, or interact with the system without authentication.

---

## 2. Key Use Cases
- **Always-On Server Display Protection**: The MacBook Air server is always running on power, never sleeping, and auto-logged in. ShieldLock starts at login, offering an overlay that keeps the server's background applications active and running, but secure.
- **Exhibition Booth Presentation Lock**: An attendee can see a slideshow presentation running in the background. If they try to click, gesture, or press keys to exit or switch windows, they are blocked. Only the booth staff can unlock the machine via Touch ID or the system password.

---

## 3. Functional Requirements

### 3.1. Secure Full-Screen Overlay Window
- **Full-Screen Coverage**: The application window must cover the entire screen (and handle multi-monitor setups if displays are attached). It must reside at an elevated window level (e.g., screen saver or status window level) to overlay the menu bar, Dock, and other application windows.
- **Visual Display Modes**:
  - **Transparent Mode (Shield)**: The overlay window is transparent or semi-transparent. The background windows (such as a slideshow, browser window, or terminal) are fully visible.
  - **Solid Mode (Blank)**: The overlay window has an opaque color (e.g., solid white, solid black) to completely obscure the desktop.
- **Input Interception**: The overlay window must intercept and swallow all mouse events (clicks, drags, scrolls) and standard keyboard input to prevent background interaction.

### 3.2. System Event & Gesture Blocking
- **App Switching Restriction**: The application must prevent the user from switching focus to other apps. Shortcuts and system gestures must be suppressed or rendered ineffective:
  - Command + Tab (Application Switcher)
  - Mission Control / Expose (F3, gestures)
  - Spotlight (Command + Space)
  - Siri / Notification Center / Launchpad
  - Swipe gestures for switching desktops/full-screen spaces
- **Termination Prevention**: Standard termination shortcuts (e.g., Command + Q) must be intercepted and ignored unless the app is successfully unlocked first.

### 3.3. Authentication & Unlocking
- **Local Authentication Integration**: The application must leverage macOS `LocalAuthentication` framework to verify identity.
- **Unlock triggers**:
  - A double-click on the overlay window, pressing a special shortcut key (e.g., Escape, Enter, or a customizable hotkey), or a visible UI action should trigger the local authentication challenge.
- **Touch ID and Password support**:
  - The application prompts for Touch ID biometric authentication.
  - If Touch ID is unavailable, fails, or is bypassed, the system fallback password sheet must be displayed.
- **Lock Dismissal**:
  - Upon successful verification, the overlay window is dismissed (closed/hidden).
  - Upon failure, the overlay remains locked and fully covers the screen.

### 3.4. Launch and Configuration
- **Start at Login**: Option to automatically launch and lock the screen upon macOS user login.
- **Lock on Launch**: Option to immediately lock the screen when the application is launched.
- **Customizable Solid Background Color**: If in Solid Mode, the user should be able to configure the background color.

---

## 4. Non-Functional Requirements
- **Security & Integrity**: The overlay must be secure and bypass-resistant. It should not expose the main desktop or background files during lock screen initialization or during system wake-from-sleep events.
- **Resource Efficiency**: Low CPU, memory, and energy footprint, as it is expected to run 24/7 on an always-on server.
- **Display Adaptability**: Gracefully handles screen resolution changes, display sleep/wake, and plugging/unplugging external monitors (dynamically creating or resizing overlay windows to cover all active screens).
- **macOS Native Design**: Written natively for macOS using Swift/Objective-C to leverage low-level Cocoa/AppKit APIs (specifically `NSWindow` levels, event taps, and `LocalAuthentication` frameworks).

---

## 5. Future Roadmap / Out-of-Scope Features
- **Bluetooth Proximity Unlock**: Automatically unlocking the overlay when a trusted Bluetooth device (e.g., iPhone or Apple Watch) is close/connected, and locking it when it disconnects.
- **Mobile Companion App**: Remote lock/unlock capability via a secure mobile app or web API.
- **Customizable Screensaver/Widgets**: Displaying custom status dashboards, clock widgets, or slideshows directly inside the Solid Mode overlay.
