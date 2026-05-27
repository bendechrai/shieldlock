import Cocoa

@MainActor
class LockContentView: NSView {
    private var hudLabel: NSTextField?
    private var fadeTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupHUD()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHUD()
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private func setupHUD() {
        let labelWidth: CGFloat = 220
        let labelHeight: CGFloat = 30
        let x = (self.bounds.width - labelWidth) / 2
        let y = (self.bounds.height - labelHeight) / 2
        
        let label = NSTextField(frame: NSRect(x: x, y: y, width: labelWidth, height: labelHeight))
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = true
        label.backgroundColor = NSColor(white: 0.0, alpha: 0.8)
        label.textColor = .white
        label.alignment = .center
        label.stringValue = "Double-click to unlock"
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.wantsLayer = true
        label.layer?.cornerRadius = 10
        label.alphaValue = 0.0
        label.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        
        self.addSubview(label)
        self.hudLabel = label
    }
    
    func showHUD() {
        fadeTimer?.invalidate()
        
        hudLabel?.alphaValue = 1.0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    self.hudLabel?.animator().alphaValue = 0.0
                }
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        if event.clickCount == 2 {
            AppGlobals.delegate?.triggerAuthentication()
        } else {
            showHUD()
        }
    }
    
    override func mouseUp(with event: NSEvent) {}
    
    override func rightMouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        showHUD()
    }
    
    override func rightMouseUp(with event: NSEvent) {}
    
    override func otherMouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        showHUD()
    }
    
    override func otherMouseUp(with event: NSEvent) {}
    
    override func scrollWheel(with event: NSEvent) {
        showHUD()
    }
    
    override func keyDown(with event: NSEvent) {
        showHUD()
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
        self.makeFirstResponder(contentView)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
