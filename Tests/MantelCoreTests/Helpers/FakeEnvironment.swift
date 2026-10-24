import AppKit

@testable import MantelCore

/// Records what WindowManager asks of the system; mutate fields to steer behavior.
@MainActor
final class FakeEnvironment {
    static let screenHeight: CGFloat = 1000

    var terminals: [pid_t: TerminalWindow] = [:]
    var missingImages: Set<String> = []
    var observerStartSucceeds = true

    private(set) var windows: [String: [FakeOverlayWindow]] = [:]
    private(set) var loadedPaths: [String] = []
    private(set) var observedTerminalPids: [pid_t] = []
    private(set) var focusObserverStarts = 0
    private(set) var terminalChangeHandlers: [pid_t: WindowEnvironment.TerminalChangeHandler] = [:]
    private(set) var focusHandler: WindowEnvironment.FocusChangeHandler?

    func addTerminal(
        pid: pid_t, bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 480), windowNumber: CGWindowID = 42
    ) {
        terminals[pid] = TerminalWindow(bounds: bounds, pid: pid, windowNumber: windowNumber)
    }

    func window(_ identifier: String) -> FakeOverlayWindow? {
        windows[identifier]?.last
    }

    var environment: WindowEnvironment {
        WindowEnvironment(
            loadImage: { [unowned self] path in
                loadedPaths.append(path)
                return missingImages.contains(path) ? nil : NSImage(size: NSSize(width: 1, height: 1))
            },
            findTerminal: { [unowned self] pid in terminals[pid] },
            primaryScreenHeight: { Self.screenHeight },
            makeWindow: { [unowned self] identifier, image, frame in
                let window = FakeOverlayWindow(identifier: identifier, image: image, frame: frame)
                windows[identifier, default: []].append(window)
                return window
            },
            observeTerminal: { [unowned self] pid, handler in
                observedTerminalPids.append(pid)
                guard observerStartSucceeds else { return nil }
                terminalChangeHandlers[pid] = handler
                return NSObject()
            },
            observeFocus: { [unowned self] handler in
                focusObserverStarts += 1
                focusHandler = handler
                return NSObject()
            },
            afterSettle: { work in work() }
        )
    }
}
