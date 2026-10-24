import Foundation

/// Drains queued operations one item per main-queue turn.
///
/// This keeps operation ordering in one place while still giving AppKit a chance
/// to process cleanup and window state changes between items.
@MainActor
public final class MainActorQueue {
    public typealias Operation = @MainActor () -> Void

    private var pendingOperations: [Operation] = []
    private var isDraining = false

    public init() {}

    public func enqueue(_ operation: @escaping Operation) {
        pendingOperations.append(operation)
        startDrainingIfNeeded()
    }

    private func startDrainingIfNeeded() {
        guard !isDraining else { return }
        isDraining = true

        DispatchQueue.main.async { [weak self] in
            self?.drainNextOperation()
        }
    }

    private func drainNextOperation() {
        guard !pendingOperations.isEmpty else {
            isDraining = false
            return
        }

        let operation = pendingOperations.removeFirst()
        operation()

        DispatchQueue.main.async { [weak self] in
            self?.drainNextOperation()
        }
    }
}
