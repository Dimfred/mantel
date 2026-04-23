import AppKit
import Foundation

/// Manages all image overlay windows.
/// Commands are queued and processed serially to avoid race conditions with AppKit.
@MainActor
final class WindowManager {
    /// Active windows keyed by identifier (e.g. "preview")
    private var windows: [String: ImageWindow] = [:]
    private var cellWidth: CGFloat = 10
    private var cellHeight: CGFloat = 20
    /// Command queue for serial processing
    private var pendingCommands: [Command] = []
    private var isProcessing = false
    /// Track last command per identifier for re-rendering on window move
    private var lastCommands: [String: Command] = [:]
    /// Window observers per terminal PID
    private var observers: [pid_t: WindowObserver] = [:]
    /// Focus observer for re-ordering on focus change
    private var focusObserver: FocusObserver?

    func setCellSize(width: CGFloat, height: CGFloat) {
        self.cellWidth = width
        self.cellHeight = height
    }

    /// Queue a command for processing.
    /// Commands are processed one at a time with a dispatch between each
    /// to let AppKit's autorelease pool drain.
    func handleCommand(_ command: Command) {
        pendingCommands.append(command)
        scheduleProcessing()
    }

    private func scheduleProcessing() {
        guard !isProcessing else { return }
        isProcessing = true

        DispatchQueue.main.async { [weak self] in
            self?.processNextCommand()
        }
    }

    /// Process commands one at a time with async dispatch between each.
    /// This gives AppKit time to clean up between operations.
    private func processNextCommand() {
        guard !pendingCommands.isEmpty else {
            isProcessing = false
            return
        }

        let command = pendingCommands.removeFirst()
        executeCommand(command)

        DispatchQueue.main.async { [weak self] in
            self?.processNextCommand()
        }
    }

    private func executeCommand(_ command: Command) {
        switch command.action {
        case .add:
            addImage(command)
        case .remove:
            removeImage(identifier: command.identifier)
        case .hide:
            windows[command.identifier]?.hide()
        case .show:
            windows[command.identifier]?.show()
        case .toggle:
            windows[command.identifier]?.toggle()
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
    }

    /// Add or update an image overlay at the specified terminal cell position.
    private func addImage(_ command: Command) {
        guard let path = command.path else {
            print("Missing path for add command")
            return
        }

        guard let image = NSImage(contentsOfFile: path) else {
            print("Failed to load image: \(path)")
            return
        }

        guard let terminalPid = command.terminalPid else {
            print("Missing terminal_pid for add command")
            return
        }

        guard let terminal = getTerminal(pid: terminalPid) else {
            print("Could not find terminal window for PID \(terminalPid)")
            return
        }

        // Convert cell coordinates to pixel frame
        let frame = calculateFrame(command, terminal: terminal)

        // Store command for re-rendering on window move
        lastCommands[command.identifier] = command

        // Start observing terminal window if not already
        if observers[terminalPid] == nil {
            let observer = WindowObserver(pid: terminalPid) { [weak self] in
                Task { @MainActor in
                    self?.handleTerminalWindowChange(pid: terminalPid)
                }
            }
            if observer.start() {
                observers[terminalPid] = observer
            }
        }

        // Start focus observer if not already running
        if focusObserver == nil {
            let obs = FocusObserver { [weak self] activePid in
                self?.handleFocusChange(activePid: activePid)
            }
            obs.start()
            focusObserver = obs
        }

        // Reuse existing window if same identifier, otherwise create new
        if let existing = windows[command.identifier] {
            print("mantel: reusing window \(command.identifier), updating frame")
            existing.updateImage(image)
            existing.updateFrame(frame)
            existing.orderAbove(windowNumber: terminal.windowNumber)
        } else {
            print("mantel: creating new window \(command.identifier)")
            let imageWindow = ImageWindow(identifier: command.identifier, image: image, frame: frame)
            windows[command.identifier] = imageWindow
            imageWindow.orderAbove(windowNumber: terminal.windowNumber)
        }
    }

    /// Called when terminal window moves or resizes - re-render all images for that terminal
    private func handleTerminalWindowChange(pid: pid_t) {
        // Small delay to let window bounds update before we query them
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { [weak self] in
            guard let self else { return }
            self.repositionImages(forTerminalPid: pid)
        }
    }

    /// Reposition existing images without going through command queue
    private func repositionImages(forTerminalPid pid: pid_t) {
        for (identifier, command) in lastCommands {
            guard command.terminalPid == pid,
                  let imageWindow = windows[identifier],
                  let terminal = getTerminal(pid: pid) else {
                continue
            }

            let frame = calculateFrame(command, terminal: terminal)
            imageWindow.updateFrame(frame)
            imageWindow.orderAbove(windowNumber: terminal.windowNumber)
        }
    }

    /// Called when any application becomes active - re-order images above their terminals
    private func handleFocusChange(activePid: pid_t) {
        // Small delay to let window z-order update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { [weak self] in
            guard let self else { return }
            print("mantel: Focus changed to \(activePid), re-ordering images")
            for (identifier, command) in self.lastCommands {
                guard let imageWindow = self.windows[identifier],
                      let terminalPid = command.terminalPid,
                      let terminal = self.getTerminal(pid: terminalPid) else {
                    continue
                }
                imageWindow.orderAbove(windowNumber: terminal.windowNumber)
            }
        }
    }

    /// Get parent PID using sysctl
    private func getParentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        let result = sysctl(&mib, 4, &info, &size, nil, 0)
        guard result == 0 else { return nil }
        return info.kp_eproc.e_ppid
    }

    /// Hide an image but keep window allocated for reuse.
    /// NOTE: We don't remove from dictionary or destroy because that causes crashes.
    /// Windows pile up over time - needs fix.
    private func removeImage(identifier: String) {
        windows[identifier]?.close()
        lastCommands.removeValue(forKey: identifier)
    }

    /// Find terminal window for given PID.
    /// Always fetches fresh bounds since terminal may have been resized.
    /// Walks up process tree if direct PID doesn't have a window.
    private func getTerminal(pid: pid_t) -> TerminalWindow? {
        // Try direct lookup - always fresh to get current bounds
        if let terminal = TerminalWindow.find(forPID: pid) {
            return terminal
        }

        // Walk up process tree to find parent terminal
        return TerminalWindow.findParentTerminal(startingFrom: pid)
    }

    /// Convert cell-based coordinates from command to pixel frame.
    /// Terminal uses (0,0) at top-left, AppKit uses bottom-left, so we flip Y.
    private func calculateFrame(_ command: Command, terminal: TerminalWindow) -> NSRect {
        let x = command.x ?? 0
        let y = command.y ?? 0
        let width = command.width ?? 10
        let height = command.height ?? 10

        let cols = command.cols ?? 80
        let rows = command.rows ?? 24

        // Calculate cell size from terminal bounds and reported dimensions
        let cellW = terminal.bounds.width / CGFloat(cols)
        let cellH = terminal.bounds.height / CGFloat(rows)

        // Get PRIMARY screen height (the one with menu bar, origin at 0,0)
        let primaryScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero })
        let primaryHeight = primaryScreen?.frame.height ?? NSScreen.main?.frame.height ?? 1080

        let pixelX = terminal.bounds.origin.x + CGFloat(x) * cellW
        let pixelWidth = CGFloat(width) * cellW
        let pixelHeight = CGFloat(height) * cellH

        // CGWindow Y is from top of primary screen, AppKit Y is from bottom
        // Image TOP should be at: terminal.top + y*cellH (in CGWindow coords)
        let imageTopInCGCoords = terminal.bounds.origin.y + CGFloat(y) * cellH
        // Convert to AppKit: flip around primary screen height, get bottom edge for NSRect
        let pixelY = primaryHeight - imageTopInCGCoords - pixelHeight

        print("mantel: terminal.bounds=\(terminal.bounds) primaryHeight=\(primaryHeight)")
        print("mantel: imageTopInCGCoords=\(imageTopInCGCoords) pixelY=\(pixelY)")

        return NSRect(x: pixelX, y: pixelY, width: pixelWidth, height: pixelHeight)
    }
}
