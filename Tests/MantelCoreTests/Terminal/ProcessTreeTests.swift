import Foundation
import Testing

@testable import MantelCore

@Suite("ProcessTree")
struct ProcessTreeTests {
    /// child -> parent
    static let tree: [pid_t: pid_t] = [500: 400, 400: 300, 300: 200, 200: 1]

    /// Walks from `start`, matching at `matchAt`; returns the match and every pid checked.
    func walk(
        from start: pid_t,
        maxHops: Int = ProcessTree.defaultMaxHops,
        parentOf: (pid_t) -> pid_t? = { tree[$0] },
        matchAt: pid_t? = nil
    ) -> (found: pid_t?, visited: [pid_t]) {
        var visited: [pid_t] = []
        let found = ProcessTree.firstAncestor(
            startingFrom: start,
            maxHops: maxHops,
            parentOf: parentOf,
            matching: { pid -> pid_t? in
                visited.append(pid)
                return pid == matchAt ? pid : nil
            })
        return (found, visited)
    }

    @Test func matchOnStartPidNeedsNoWalk() {
        let result = walk(from: 500, matchAt: 500)

        #expect(result.found == 500)
        #expect(result.visited == [500])
    }

    @Test func walksUpUntilMatch() {
        let result = walk(from: 500, matchAt: 300)

        #expect(result.found == 300)
        #expect(result.visited == [500, 400, 300])
    }

    @Test func stopsAtLaunchd() {
        let result = walk(from: 500)

        #expect(result.found == nil)
        #expect(result.visited == [500, 400, 300, 200])
    }

    @Test func unknownParentStops() {
        let result = walk(from: 999, parentOf: { _ in nil })

        #expect(result.found == nil)
        #expect(result.visited == [999])
    }

    @Test func respectsMaxHopsOnCycle() {
        let result = walk(from: 10, maxHops: 4, parentOf: { $0 == 10 ? 11 : 10 })

        #expect(result.found == nil)
        #expect(result.visited == [10, 11, 10, 11])
    }

    @Test func parentPidOfCurrentProcessMatchesGetppid() {
        #expect(ProcessTree.parentPID(of: getpid()) == getppid())
    }

    @Test func parentPidOfMissingProcessIsNil() {
        #expect(ProcessTree.parentPID(of: pid_t(Int32.max)) == nil)
    }
}
