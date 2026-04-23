import AppKit
import Foundation

/// Path to FIFO for receiving commands from shell scripts
let fifoPath = "/tmp/mantel.fifo"

/// App delegate that owns the window manager and FIFO server.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let windowManager = WindowManager()
    var server: FifoServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager.setCellSize(width: 10, height: 20)

        // Commands come from background thread, dispatch to main for AppKit
        server = FifoServer(fifoPath: fifoPath) { [weak self] command in
            DispatchQueue.main.async {
                self?.windowManager.handleCommand(command)
            }
        }

        do {
            try server?.start()
        } catch {
            print("Failed to start server: \(error)")
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        server?.stop()
    }
}

/// Entry point. Runs as accessory app (no dock icon, no menu bar).
@main
struct Mantel {
    static func main() {
        print("mantel daemon starting...")
        print("FIFO: \(fifoPath)")

        // Handle Ctrl-C gracefully
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
        // Accessory = no dock icon, no main menu
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate()
        app.delegate = delegate

        // Blocks until app terminates
        app.run()
    }
}
