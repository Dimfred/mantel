import AppKit

/// System dependencies of WindowManager, swappable in tests.
@MainActor
struct WindowEnvironment {
    typealias TerminalChangeHandler = @Sendable () -> Void
    typealias FocusChangeHandler = (pid_t) -> Void

    var loadImage: (String) -> NSImage?
    var findTerminal: (pid_t) -> TerminalWindow?
    var primaryScreenHeight: () -> CGFloat
    var makeWindow: (String, NSImage, NSRect) -> OverlayWindow
    /// Returns a token that keeps the observer alive, nil if it could not start.
    var observeTerminal: (pid_t, @escaping TerminalChangeHandler) -> AnyObject?
    var observeFocus: (@escaping FocusChangeHandler) -> AnyObject?
    /// Defers work until AppKit has updated window bounds / z-order.
    var afterSettle: (@escaping @MainActor () -> Void) -> Void

    static let settleDelay: TimeInterval = 0.016
    static let fallbackScreenHeight: CGFloat = 1080

    static var live: WindowEnvironment {
        WindowEnvironment(
            loadImage: { path in NSImage(contentsOfFile: path) },
            findTerminal: TerminalWindow.findOwningTerminal(pid:),
            primaryScreenHeight: {
                let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                return primary?.frame.height ?? NSScreen.main?.frame.height ?? fallbackScreenHeight
            },
            makeWindow: { identifier, image, frame in
                ImageWindow(identifier: identifier, image: image, frame: frame)
            },
            observeTerminal: { pid, onChange in
                let observer = WindowObserver(pid: pid, onWindowChange: onChange)
                return observer.start() ? observer : nil
            },
            observeFocus: { onChange in
                let observer = FocusObserver(onFocusChange: onChange)
                observer.start()
                return observer
            },
            afterSettle: { work in
                DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay) {
                    work()
                }
            }
        )
    }
}
