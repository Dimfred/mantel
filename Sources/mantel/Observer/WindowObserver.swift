import AppKit
import ApplicationServices

/// Observes external window move/resize events using the Accessibility API.
/// Requires accessibility permissions (System Preferences > Privacy > Accessibility).
final class WindowObserver: @unchecked Sendable {
    private var observer: AXObserver?
    private let pid: pid_t
    private let callback: @Sendable () -> Void

    init(pid: pid_t, onWindowChange: @escaping @Sendable () -> Void) {
        self.pid = pid
        self.callback = onWindowChange
    }

    deinit {
        if let obs = observer {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(obs),
                .defaultMode
            )
        }
    }

    /// Start observing window events for the target process.
    /// Returns false if accessibility access is denied.
    func start() -> Bool {
        // Check accessibility permissions
        // "AXTrustedCheckOptionPrompt" is the raw string value of kAXTrustedCheckOptionPrompt
        let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            logger.error("Accessibility access denied")
            return false
        }

        // Create observer for the target PID
        var observerRef: AXObserver?
        let result = AXObserverCreate(pid, observerCallback, &observerRef)
        guard result == .success, let obs = observerRef else {
            logger.error("Failed to create AXObserver: \(result.rawValue, privacy: .public)")
            return false
        }
        self.observer = obs

        // Get the application element
        let appElement = AXUIElementCreateApplication(pid)

        // Register for window notifications
        let notifications: [CFString] = [
            kAXWindowMovedNotification as CFString,
            kAXWindowResizedNotification as CFString,
            kAXFocusedWindowChangedNotification as CFString,
            kAXMainWindowChangedNotification as CFString,
        ]

        // Store self pointer for callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        for notification in notifications {
            let err = AXObserverAddNotification(obs, appElement, notification, selfPtr)
            if err != .success {
                logger.error(
                    "Failed to add notification \(notification as String, privacy: .public): \(err.rawValue, privacy: .public)"
                )
            }
        }

        // Add observer to run loop
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(obs),
            .defaultMode
        )

        logger.info("WindowObserver started for PID \(self.pid, privacy: .public)")
        return true
    }

    func stop() {
        if let obs = observer {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(obs),
                .defaultMode
            )
            observer = nil
            logger.info("WindowObserver stopped")
        }
    }

    fileprivate func handleNotification(_ notification: String) {
        logger.debug("Window event: \(notification, privacy: .public)")
        callback()
    }
}

/// C callback that bridges to Swift
private func observerCallback(
    observer: AXObserver,
    element: AXUIElement,
    notification: CFString,
    refcon: UnsafeMutableRawPointer?
) {
    guard let refcon = refcon else { return }
    let windowObserver = Unmanaged<WindowObserver>.fromOpaque(refcon).takeUnretainedValue()
    let notificationStr = notification as String
    DispatchQueue.main.async { [windowObserver, notificationStr] in
        windowObserver.handleNotification(notificationStr)
    }
}
