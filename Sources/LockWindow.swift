import Cocoa

@MainActor
class LockContentView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@MainActor
class LockWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullScreen],
            backing: .buffered,
            defer: false
        )
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.backgroundColor = NSColor(white: 0.0, alpha: 0.005)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        
        let contentView = LockContentView(frame: screen.frame)
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
