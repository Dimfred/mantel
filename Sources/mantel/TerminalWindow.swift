import CoreGraphics
import Foundation

/// Represents a terminal window's bounds, found via CGWindowList API.
/// Used to position image overlays relative to terminal content area.
struct TerminalWindow {
    /// Window bounds in screen coordinates (Y=0 at top)
    let bounds: CGRect
    let pid: pid_t

    /// Find window owned by specific PID using CGWindowList.
    /// Returns first matching on-screen window.
    static func find(forPID pid: pid_t) -> TerminalWindow? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else {
                continue
            }

            let bounds = CGRect(x: x, y: y, width: width, height: height)
            return TerminalWindow(bounds: bounds, pid: pid)
        }

        return nil
    }

    /// Find terminal starting from current process's parent.
    static func findParentTerminal() -> TerminalWindow? {
        return findParentTerminal(startingFrom: getppid())
    }

    /// Walk up process tree to find first ancestor with a window.
    /// Shell processes don't have windows, but their parent terminal does.
    /// Limits to 10 hops to avoid infinite loops.
    static func findParentTerminal(startingFrom pid: pid_t) -> TerminalWindow? {
        var currentPID = pid

        for _ in 0..<10 {
            if let window = find(forPID: currentPID) {
                return window
            }
            currentPID = getParentPID(of: currentPID) ?? 1
            if currentPID <= 1 {
                break
            }
        }

        return nil
    }

    /// Get parent PID using sysctl.
    private static func getParentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]

        let result = sysctl(&mib, 4, &info, &size, nil, 0)
        guard result == 0 else { return nil }

        return info.kp_eproc.e_ppid
    }
}
