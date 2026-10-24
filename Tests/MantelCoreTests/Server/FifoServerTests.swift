import Foundation
import Testing

@testable import MantelCore

@Suite("FifoServer")
struct FifoServerTests {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("mantel-test-\(UUID().uuidString).fifo").path

    func makeServer() -> (FifoServer, AsyncStream<Command>) {
        let (stream, continuation) = AsyncStream<Command>.makeStream()
        let server = FifoServer(fifoPath: path) { command in
            continuation.yield(command)
        }
        return (server, stream)
    }

    func write(_ payload: String) async throws {
        let target = path
        try await Task.detached {
            let handle = try #require(FileHandle(forWritingAtPath: target))
            try handle.write(contentsOf: Data(payload.utf8))
            try handle.close()
        }.value
    }

    func next(_ iterator: inout AsyncStream<Command>.Iterator) async -> Command? {
        await iterator.next()
    }

    func identifier(of command: Command?) -> String? {
        switch command {
        case .hide(let c), .show(let c), .toggle(let c), .remove(let c): c.identifier
        case .add(let c): c.identifier
        case .clear, nil: nil
        }
    }

    @Test func startCreatesFifo() throws {
        let (server, _) = makeServer()
        try server.start()
        defer { server.stop() }

        #expect(isFifo(path))
    }

    @Test(.timeLimit(.minutes(1))) func dispatchesWrittenCommand() async throws {
        let (server, stream) = makeServer()
        try server.start()
        defer { server.stop() }
        var iterator = stream.makeAsyncIterator()

        try await write(#"{"action":"hide","identifier":"preview"}"#)

        let command = await next(&iterator)
        guard case .hide(let hide) = command else {
            Issue.record("Expected hide, got \(String(describing: command))")
            return
        }
        #expect(hide.identifier == "preview")
    }

    @Test(.timeLimit(.minutes(1))) func dispatchesSequentialWritesInOrder() async throws {
        let (server, stream) = makeServer()
        try server.start()
        defer { server.stop() }
        var iterator = stream.makeAsyncIterator()

        var received: [String?] = []
        for id in ["a", "b", "c"] {
            try await write(#"{"action":"show","identifier":"\#(id)"}"#)
            received.append(identifier(of: await next(&iterator)))
        }

        #expect(received == ["a", "b", "c"])
    }

    @Test(.timeLimit(.minutes(1))) func invalidJsonIsSkippedAndServerKeepsReading() async throws {
        let (server, stream) = makeServer()
        try server.start()
        defer { server.stop() }
        var iterator = stream.makeAsyncIterator()

        try await write("not json")
        // No ack for a dropped message; back-to-back writes race the reader's close (T010).
        try await Task.sleep(for: .milliseconds(200))
        try await write(#"{"action":"clear"}"#)

        let command = await next(&iterator)
        guard case .clear = command else {
            Issue.record("Expected clear, got \(String(describing: command))")
            return
        }
    }

    @Test func startReplacesStaleFileAtPath() throws {
        #expect(FileManager.default.createFile(atPath: path, contents: Data("stale".utf8)))
        let (server, _) = makeServer()

        try server.start()
        defer { server.stop() }

        #expect(isFifo(path))
    }

    @Test func stopRemovesFifo() throws {
        let (server, _) = makeServer()
        try server.start()

        server.stop()

        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test func startInMissingDirectoryThrows() {
        let server = FifoServer(fifoPath: "/nonexistent-\(UUID().uuidString)/mantel.fifo") { _ in }

        #expect(throws: FifoError.createFailed(errno: ENOENT)) {
            try server.start()
        }
    }
}

private func isFifo(_ path: String) -> Bool {
    var info = stat()
    guard stat(path, &info) == 0 else { return false }
    return (info.st_mode & S_IFMT) == S_IFIFO
}
