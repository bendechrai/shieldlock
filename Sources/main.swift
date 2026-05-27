import Cocoa
import ApplicationServices
import ServiceManagement
import IOKit
import IOKit.pwr_mgt

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var isTrusted: Bool = false
    private var lockWindows: [LockWindow] = []
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private var hasDisplayAssertion = false
    private var hasSystemAssertion = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !isTrusted {
            setupFallbackWindow()
        } else {
            setupTrustedState()
        }
    }
    
    private func setupFallbackWindow() {
        let mask: NSWindow.StyleMask = [.titled, .closable]
        let windowWidth: CGFloat = 450
        let windowHeight: CGFloat = 200
        
        let mainScreen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = mainScreen?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowFrame = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )
        
        let win = NSWindow(
            contentRect: windowFrame,
            styleMask: mask,
            backing: .buffered,
            defer: false
        )
        win.title = "ShieldLock - Permission Required"
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        
        let label = NSTextField(frame: NSRect(x: 20, y: 70, width: windowWidth - 40, height: 100))
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.stringValue = "ShieldLock requires Accessibility Permissions to secure the keyboard/gestures.\n\nPlease grant permissions in System Settings > Privacy & Security > Accessibility, then relaunch the app."
        label.font = NSFont.systemFont(ofSize: 14)
        contentView.addSubview(label)
        
        let button = NSButton(frame: NSRect(x: (windowWidth - 180) / 2, y: 20, width: 180, height: 32))
        button.title = "Open System Settings"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(openSystemSettings(_:))
        contentView.addSubview(button)
        
        win.contentView = contentView
        win.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        self.window = win
    }
    
    private func setupTrustedState() {
        do {
            if SMAppService.mainApp.status == .notRegistered {
                try SMAppService.mainApp.register()
            }
        } catch {
        }
        NSApp.setActivationPolicy(.accessory)
        
        NSApplication.shared.presentationOptions = [
            .hideDock,
            .hideMenuBar,
            .disableProcessSwitching,
            .disableForceQuit,
            .disableSessionTermination,
            .disableHideApplication
        ]
        
        preventSleep()
        setupLockWindows()
        setupEventTap()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func setupLockWindows() {
        for window in lockWindows {
            window.close()
        }
        lockWindows.removeAll()
        
        for screen in NSScreen.screens {
            let lockWindow = LockWindow(screen: screen)
            lockWindows.append(lockWindow)
            lockWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << 29) |
                        (1 << 30)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            return
        }
        
        EventTapHolder.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    @objc private func screenParametersChanged(_ notification: Notification) {
        setupLockWindows()
    }
    
    private func preventSleep() {
        let reason = "ShieldLock screen lock active" as CFString
        
        var assertionID: IOPMAssertionID = 0
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if displayResult == kIOReturnSuccess {
            displayAssertionID = assertionID
            hasDisplayAssertion = true
        }
        
        var sysAssertionID: IOPMAssertionID = 0
        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &sysAssertionID
        )
        if systemResult == kIOReturnSuccess {
            systemAssertionID = sysAssertionID
            hasSystemAssertion = true
        }
    }
    
    private func allowSleep() {
        if hasDisplayAssertion {
            IOPMAssertionRelease(displayAssertionID)
            hasDisplayAssertion = false
        }
        if hasSystemAssertion {
            IOPMAssertionRelease(systemAssertionID)
            hasSystemAssertion = false
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        allowSleep()
        for window in lockWindows {
            window.close()
        }
        lockWindows.removeAll()
        NSApplication.shared.presentationOptions = []
    }
    
    @objc func openSystemSettings(_ sender: Any) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return !isTrusted
    }
}

struct EventTapHolder {
    nonisolated(unsafe) static var eventTap: CFMachPort?
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = EventTapHolder.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return nil
    }
    
    if type == .keyDown || type == .keyUp {
        if let nsEvent = NSEvent(cgEvent: event) {
            let chars = nsEvent.charactersIgnoringModifiers ?? ""
            if chars.lowercased() == "u" {
                return Unmanaged.passRetained(event)
            }
        }
    }
    
    return nil
}

struct AppGlobals {
    @MainActor static var delegate: AppDelegate?
}

@MainActor
func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    
    let isTrusted = AXIsProcessTrusted()
    delegate.isTrusted = isTrusted
    
    if !isTrusted {
        app.setActivationPolicy(.regular)
    } else {
        app.setActivationPolicy(.accessory)
    }
    
    AppGlobals.delegate = delegate
    app.delegate = delegate
    app.run()
}

main()
