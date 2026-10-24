import AppKit
import Foundation

/// Manages all image overlay windows.
/// Commands are queued one at a time to give AppKit a run-loop turn between operations.
@MainActor
public final class WindowManager {
    private let commandQueue = MainActorQueue()
    private let env: WindowEnvironment

    /// Windows keyed by identifier (e.g. "preview"); kept after remove for reuse
    private var windows: [String: OverlayWindow] = [:]

    /// Last add command per identifier for re-rendering on window move; absent = removed
    private var lastAddCommands: [String: AddCommand] = [:]

    /// Observer tokens per terminal PID
    private var observers: [pid_t: AnyObject] = [:]
    private var focusObserver: AnyObject?

    public convenience init() {
        self.init(environment: .live)
    }

    init(environment: WindowEnvironment) {
        self.env = environment
    }

    /// Queue a command for processing.
    public func handleCommand(_ command: Command) {
        commandQueue.enqueue { [weak self] in
            self?.execute(command)
        }
    }

    func execute(_ command: Command) {
        switch command {
        case .add(let addCommand):
            addImage(addCommand)
        case .remove(let removeCommand):
            removeImage(identifier: removeCommand.identifier)
        case .hide(let hideCommand):
            windows[hideCommand.identifier]?.hide()
        case .show(let showCommand):
            showImage(identifier: showCommand.identifier)
        case .toggle(let toggleCommand):
            toggleImage(identifier: toggleCommand.identifier)
        case .clear:
            clearAll()
        }
    }

    /// Destroy all windows. Only time we actually call destroy().
    private func clearAll() {
        for (_, window) in windows {
            window.destroy()
        }
        windows.removeAll()
        lastAddCommands.removeAll()
    }

    /// Add or update an image overlay at the specified terminal cell position.
    private func addImage(_ command: AddCommand) {
        let path = command.path
        guard let image = env.loadImage(path) else {
            logger.error("Failed to load image: \(path, privacy: .private)")
            return
        }

        let terminalPid = command.terminalPid
        guard let terminal = env.findTerminal(terminalPid) else {
            logger.error("Could not find terminal window for PID \(terminalPid, privacy: .public)")
            return
        }

        let frame: NSRect
        do {
            frame = try CellFrame.frame(
                for: command, terminalBounds: terminal.bounds, primaryScreenHeight: env.primaryScreenHeight())
        } catch {
            logger.error("Invalid frame for \(command.identifier, privacy: .public): \(error)")
            return
        }

        lastAddCommands[command.identifier] = command
        startObservers(terminalPid: terminalPid)

        if let existing = windows[command.identifier] {
            logger.debug("Reusing window \(command.identifier, privacy: .public), updating frame")
            existing.updateImage(image)
            existing.updateFrame(frame)
            existing.orderAbove(windowNumber: terminal.windowNumber)
            return
        }

        logger.debug("Creating new window \(command.identifier, privacy: .public)")
        let imageWindow = env.makeWindow(command.identifier, image, frame)
        windows[command.identifier] = imageWindow
        imageWindow.orderAbove(windowNumber: terminal.windowNumber)
    }

    private func startObservers(terminalPid: pid_t) {
        if observers[terminalPid] == nil {
            let token = env.observeTerminal(terminalPid) { [weak self] in
                Task { @MainActor in
                    self?.handleTerminalWindowChange(pid: terminalPid)
                }
            }
            if let token {
                observers[terminalPid] = token
            }
        }

        if focusObserver == nil {
            focusObserver = env.observeFocus { [weak self] activePid in
                self?.handleFocusChange(activePid: activePid)
            }
        }
    }

    /// Show above its terminal; `orderFront` would put it above every other app too.
    private func showImage(identifier: String) {
        guard let command = lastAddCommands[identifier],
            let window = windows[identifier],
            let terminal = env.findTerminal(command.terminalPid)
        else {
            return
        }
        window.orderAbove(windowNumber: terminal.windowNumber)
    }

    private func toggleImage(identifier: String) {
        guard let window = windows[identifier] else { return }
        if window.isVisible {
            window.hide()
            return
        }
        showImage(identifier: identifier)
    }

    /// Hide an image but keep window allocated for reuse.
    /// NOTE: We don't remove from dictionary or destroy because that causes crashes.
    /// Windows pile up over time - needs fix.
    private func removeImage(identifier: String) {
        windows[identifier]?.close()
        lastAddCommands.removeValue(forKey: identifier)
    }

    /// Called when terminal window moves or resizes - re-render all images for that terminal
    func handleTerminalWindowChange(pid: pid_t) {
        env.afterSettle { [weak self] in
            self?.repositionImages(forTerminalPid: pid)
        }
    }

    /// Hidden windows only get their frame updated; ordering would make them visible again.
    private func repositionImages(forTerminalPid pid: pid_t) {
        let commands = lastAddCommands.filter { $0.value.terminalPid == pid }
        guard !commands.isEmpty, let terminal = env.findTerminal(pid) else { return }

        let screenHeight = env.primaryScreenHeight()
        for (identifier, command) in commands {
            guard let imageWindow = windows[identifier] else { continue }
            let frame: NSRect
            do {
                frame = try CellFrame.frame(
                    for: command, terminalBounds: terminal.bounds, primaryScreenHeight: screenHeight)
            } catch {
                logger.error("Invalid frame for \(identifier, privacy: .public): \(error)")
                continue
            }

            imageWindow.updateFrame(frame)
            if imageWindow.isVisible {
                imageWindow.orderAbove(windowNumber: terminal.windowNumber)
            }
        }
    }

    /// Called when any application becomes active - re-order images above their terminals
    func handleFocusChange(activePid: pid_t) {
        env.afterSettle { [weak self] in
            logger.debug("Focus changed to \(activePid, privacy: .public), re-ordering images")
            self?.reorderVisibleImages()
        }
    }

    private func reorderVisibleImages() {
        for (identifier, command) in lastAddCommands {
            guard let imageWindow = windows[identifier], imageWindow.isVisible,
                let terminal = env.findTerminal(command.terminalPid)
            else {
                continue
            }
            imageWindow.orderAbove(windowNumber: terminal.windowNumber)
        }
    }
}
