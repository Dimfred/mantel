import AppKit
import Foundation

/// Wrapper around NSWindow for displaying an image overlay.
/// The window is borderless, transparent, and floats above other windows.
@MainActor
final class ImageWindow {
    let identifier: String
    let window: NSWindow
    private let imageView: NSImageView

    init(identifier: String, image: NSImage, frame: NSRect) {
        self.identifier = identifier
        print("mantel: ImageWindow.init frame=\(frame)")

        // Borderless window that can display transparency
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // Set position explicitly after creation
        window.setFrameOrigin(frame.origin)
        print("mantel: ImageWindow.init window.frame=\(window.frame)")
        window.isOpaque = false
        window.backgroundColor = .clear
        // Float above normal windows (including terminal)
        window.level = .floating
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

    /// Make window visible
    func show() {
        window.orderFront(nil)
    }

    /// Hide window without destroying it
    func hide() {
        window.orderOut(nil)
    }

    func toggle() {
        if window.isVisible {
            hide()
        } else {
            show()
        }
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
        print("mantel: updateFrame requested=\(frame)")
        window.setFrame(frame, display: true)
        print("mantel: updateFrame actual=\(window.frame)")
        imageView.frame = NSRect(origin: .zero, size: frame.size)
    }

    /// Replace displayed image
    func updateImage(_ image: NSImage) {
        imageView.image = image
    }
}
