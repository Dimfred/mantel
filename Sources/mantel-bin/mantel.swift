import AppKit
import Foundation
import MantelCore

/// App delegate that owns the window manager and FIFO server.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var fifoServer: FifoServer?
    let windowManager = WindowManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        fifoServer = FifoServer(fifoPath: defaultFifoPath) { [weak self] command in
            DispatchQueue.main.async {
                self?.windowManager.handleCommand(command)
            }
        }

        do {
            try fifoServer?.start()
        } catch {
            logger.error("Failed to start server: \(error)")
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        fifoServer?.stop()
    }
}

/// Entry point. Runs as accessory app (no dock icon, no menu bar).
@main
struct Mantel {
    static func main() {
        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
        signal(SIGTERM) { _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
