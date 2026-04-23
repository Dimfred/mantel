import AppKit
import Foundation

/// Observes application focus changes using NSWorkspace notifications.
/// Calls back when any application becomes active.
@MainActor
final class FocusObserver {
    private let callback: (pid_t) -> Void
    private var observation: NSObjectProtocol?

    init(onFocusChange: @escaping (pid_t) -> Void) {
        self.callback = onFocusChange
    }

    func start() {
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            let pid = app.processIdentifier
            Task { @MainActor in
                self.callback(pid)
            }
        }
        print("mantel: FocusObserver started")
    }

    func stop() {
        if let obs = observation {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observation = nil
            print("mantel: FocusObserver stopped")
        }
    }
}
