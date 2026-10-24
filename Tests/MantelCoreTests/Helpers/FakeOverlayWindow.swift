import AppKit

@testable import MantelCore

@MainActor
final class FakeOverlayWindow: OverlayWindow {
    enum Call: Equatable {
        case orderAbove(CGWindowID)
        case hide
        case close
        case destroy
        case updateFrame(NSRect)
        case updateImage
    }

    let identifier: String
    private(set) var frame: NSRect
    private(set) var image: NSImage?
    private(set) var calls: [Call] = []
    private(set) var isVisible = false

    init(identifier: String, image: NSImage, frame: NSRect) {
        self.identifier = identifier
        self.image = image
        self.frame = frame
    }

    func orderAbove(windowNumber: CGWindowID) {
        calls.append(.orderAbove(windowNumber))
        isVisible = true
    }

    func hide() {
        calls.append(.hide)
        isVisible = false
    }

    func close() {
        calls.append(.close)
        isVisible = false
        image = nil
    }

    func destroy() {
        calls.append(.destroy)
        isVisible = false
        image = nil
    }

    func updateFrame(_ frame: NSRect) {
        calls.append(.updateFrame(frame))
        self.frame = frame
    }

    func updateImage(_ image: NSImage) {
        calls.append(.updateImage)
        self.image = image
    }

    func resetCalls() {
        calls.removeAll()
    }
}
