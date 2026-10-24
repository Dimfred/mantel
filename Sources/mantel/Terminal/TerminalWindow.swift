import CoreGraphics
import Foundation

/// Represents a terminal window's bounds, found via CGWindowList API.
/// Used to position image overlays relative to terminal content area.
struct TerminalWindow: Equatable {
    /// Window bounds in screen coordinates (Y=0 at top)
    let bounds: CGRect
    let pid: pid_t
    /// CGWindowID for z-ordering
    let windowNumber: CGWindowID

    typealias WindowInfo = [String: Any]

    /// Find window owned by specific PID using CGWindowList.
    /// Returns first matching on-screen window.
    static func find(forPID pid: pid_t) -> TerminalWindow? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [WindowInfo] else {
            return nil
        }
        return find(forPID: pid, in: windowList)
    }

    /// Pick the first window in `windowList` owned by `pid` with complete bounds.
    static func find(forPID pid: pid_t, in windowList: [WindowInfo]) -> TerminalWindow? {
        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                ownerPID == pid,
                let windowNum = window[kCGWindowNumber as String] as? CGWindowID,
                let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                let x = boundsDict["X"],
                let y = boundsDict["Y"],
                let width = boundsDict["Width"],
                let height = boundsDict["Height"]
            else {
                continue
            }

            let bounds = CGRect(x: x, y: y, width: width, height: height)
            return TerminalWindow(bounds: bounds, pid: pid, windowNumber: windowNum)
        }

        return nil
    }

    /// Find the terminal window for `pid`, walking up the process tree if needed.
    /// Always fetches fresh bounds since the terminal may have been resized.
    static func findOwningTerminal(pid: pid_t) -> TerminalWindow? {
        return ProcessTree.firstAncestor(startingFrom: pid, matching: find(forPID:))
    }
}
