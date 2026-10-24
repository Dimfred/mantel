import AppKit

/// What WindowManager needs from an overlay window; ImageWindow is the AppKit impl.
@MainActor
protocol OverlayWindow: AnyObject {
    var isVisible: Bool { get }
    func orderAbove(windowNumber: CGWindowID)
    func hide()
    func close()
    func destroy()
    func updateFrame(_ frame: NSRect)
    func updateImage(_ image: NSImage)
}
