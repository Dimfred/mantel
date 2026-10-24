import Foundation

/// Walks the process tree via sysctl.
enum ProcessTree {
    static let defaultMaxHops = 10

    /// Walk up from `pid` and return the first non-nil `match` result.
    /// Shell processes don't have windows, but their parent terminal does.
    /// Stops at launchd (pid <= 1) or after `maxHops` to avoid infinite loops.
    static func firstAncestor<T>(
        startingFrom pid: pid_t,
        maxHops: Int = defaultMaxHops,
        parentOf: (pid_t) -> pid_t? = parentPID(of:),
        matching match: (pid_t) -> T?
    ) -> T? {
        var currentPID = pid

        for _ in 0..<maxHops {
            if let found = match(currentPID) {
                return found
            }
            currentPID = parentOf(currentPID) ?? 1
            if currentPID <= 1 {
                break
            }
        }

        return nil
    }

    static func parentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]

        let result = sysctl(&mib, 4, &info, &size, nil, 0)
        guard result == 0, size > 0 else { return nil }

        return info.kp_eproc.e_ppid
    }
}
