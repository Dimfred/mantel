import CoreGraphics
import Testing

@testable import MantelCore

@Suite("TerminalWindow")
struct TerminalWindowTests {
    func info(
        pid: pid_t, number: CGWindowID, bounds: [String: CGFloat] = ["X": 1, "Y": 2, "Width": 300, "Height": 200]
    ) -> TerminalWindow.WindowInfo {
        [
            kCGWindowOwnerPID as String: pid,
            kCGWindowNumber as String: number,
            kCGWindowBounds as String: bounds,
        ]
    }

    @Test func findsWindowOwnedByPid() {
        let list = [info(pid: 1, number: 10), info(pid: 7, number: 70)]

        let found = TerminalWindow.find(forPID: 7, in: list)

        #expect(found == TerminalWindow(bounds: CGRect(x: 1, y: 2, width: 300, height: 200), pid: 7, windowNumber: 70))
    }

    @Test func returnsFirstMatchInListOrder() {
        let list = [info(pid: 7, number: 71), info(pid: 7, number: 72)]

        #expect(TerminalWindow.find(forPID: 7, in: list)?.windowNumber == 71)
    }

    @Test func noMatchingPidReturnsNil() {
        #expect(TerminalWindow.find(forPID: 9, in: [info(pid: 1, number: 10)]) == nil)
        #expect(TerminalWindow.find(forPID: 9, in: []) == nil)
    }

    @Test func skipsWindowsWithIncompleteBounds() {
        let list = [
            info(pid: 7, number: 71, bounds: ["X": 0, "Y": 0, "Width": 10]),
            info(pid: 7, number: 72),
        ]

        #expect(TerminalWindow.find(forPID: 7, in: list)?.windowNumber == 72)
    }

    @Test func skipsWindowsWithoutNumber() {
        var broken = info(pid: 7, number: 71)
        broken.removeValue(forKey: kCGWindowNumber as String)

        #expect(TerminalWindow.find(forPID: 7, in: [broken]) == nil)
    }
}
