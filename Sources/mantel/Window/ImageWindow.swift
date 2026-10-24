import AppKit
import Foundation

/// Wrapper around NSWindow for displaying an image overlay.
/// The window is borderless, transparent, and floats above other windows.
@MainActor
final class ImageWindow: OverlayWindow {
    let identifier: String
    let window: NSWindow
    private let imageView: NSImageView

    init(identifier: String, image: NSImage, frame: NSRect) {
        self.identifier = identifier
        logger.debug("ImageWindow.init frame=\(String(describing: frame), privacy: .public)")

        // Borderless window that can display transparency
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // Set position explicitly after creation
        window.setFrameOrigin(frame.origin)
        logger.debug("ImageWindow.init window.frame=\(String(describing: window.frame), privacy: .public)")
        window.isOpaque = false
        window.backgroundColor = .clear
        // Same level as normal windows for proper z-ordering
        window.level = .normal
        // Don't intercept mouse events - let them pass through to terminal
        window.ignoresMouseEvents = true
        // Visible on all spaces/desktops
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: frame.size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        // Ensure transparency works
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = .clear
        window.contentView = imageView

        self.window = window
        self.imageView = imageView
    }

    var isVisible: Bool {
        window.isVisible
    }

    /// Order this window just above the given window number (also makes it visible)
    func orderAbove(windowNumber: CGWindowID) {
        window.order(.above, relativeTo: Int(windowNumber))
    }

    /// Hide window without destroying it
    func hide() {
        window.orderOut(nil)
    }

    /// Hide and clear image - window stays allocated for reuse.
    /// NOTE: We don't actually destroy windows here because calling NSWindow.close()
    /// and then creating a new window causes crashes in objc_autoreleasePoolPop.
    /// This is a workaround - windows pile up over time. Needs proper fix.
    func close() {
        window.orderOut(nil)
        imageView.image = nil
    }

    /// Actually destroy the window - only used in clearAll.
    /// WARNING: May cause crashes if window is recreated quickly after.
    func destroy() {
        window.orderOut(nil)
        imageView.image = nil
        window.contentView = nil
        window.close()
    }

    /// Update window position and size
    func updateFrame(_ frame: NSRect) {
        logger.debug("updateFrame requested=\(String(describing: frame), privacy: .public)")
        window.setFrame(frame, display: true)
        logger.debug("updateFrame actual=\(String(describing: self.window.frame), privacy: .public)")
        imageView.frame = NSRect(origin: .zero, size: frame.size)
    }

    /// Replace displayed image
    func updateImage(_ image: NSImage) {
        imageView.image = image
    }
}
