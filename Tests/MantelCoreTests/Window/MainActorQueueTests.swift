import Foundation
import Testing

@testable import MantelCore

@MainActor
@Suite("MainActorQueue")
struct MainActorQueueTests {
    func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 where !condition() {
            try await Task.sleep(for: .milliseconds(2))
        }
    }

    @Test func runsOperationsInEnqueueOrder() async throws {
        let queue = MainActorQueue()
        var log: [Int] = []

        for i in 0..<5 {
            queue.enqueue { log.append(i) }
        }
        try await waitUntil { log.count == 5 }

        #expect(log == [0, 1, 2, 3, 4])
    }

    @Test func enqueueDoesNotRunSynchronously() {
        let queue = MainActorQueue()
        var ran = false

        queue.enqueue { ran = true }

        #expect(!ran)
    }

    @Test func operationEnqueuedFromOperationRunsAfterPending() async throws {
        let queue = MainActorQueue()
        var log: [String] = []

        queue.enqueue {
            log.append("a")
            queue.enqueue { log.append("nested") }
        }
        queue.enqueue { log.append("b") }
        try await waitUntil { log.count == 3 }

        #expect(log == ["a", "b", "nested"])
    }

    @Test func runsOneOperationPerMainQueueTurn() async throws {
        let queue = MainActorQueue()
        var log: [String] = []

        queue.enqueue {
            log.append("first")
            DispatchQueue.main.async { log.append("appkit turn") }
        }
        queue.enqueue { log.append("second") }
        try await waitUntil { log.count == 3 }

        #expect(log == ["first", "appkit turn", "second"])
    }

    @Test func restartsAfterDraining() async throws {
        let queue = MainActorQueue()
        var log: [Int] = []

        queue.enqueue { log.append(1) }
        try await waitUntil { log.count == 1 }
        queue.enqueue { log.append(2) }
        try await waitUntil { log.count == 2 }

        #expect(log == [1, 2])
    }
}
