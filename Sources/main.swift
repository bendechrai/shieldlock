import Cocoa
import ApplicationServices
import ServiceManagement

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var isTrusted: Bool = false
    
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
