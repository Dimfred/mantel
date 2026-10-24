import Foundation

public enum FifoError: Error, Equatable {
    case createFailed(errno: Int32)
}

/// Reads JSON commands from a named pipe (FIFO).
/// Runs a background read loop and dispatches parsed commands to handler.
public final class FifoServer: @unchecked Sendable {
    private let fifoPath: String
    private var isRunning = false
    private let commandHandler: @Sendable (Command) -> Void

    public init(fifoPath: String, commandHandler: @escaping @Sendable (Command) -> Void) {
        self.fifoPath = fifoPath
        self.commandHandler = commandHandler
    }

    deinit {
        stop()
    }

    /// Create FIFO and start background read loop.
    public func start() throws {
        // Remove stale FIFO if exists
        unlink(fifoPath)

        let result = mkfifo(fifoPath, 0o666)
        guard result == 0 else {
            throw FifoError.createFailed(errno: errno)
        }

        logger.info("Listening on \(self.fifoPath, privacy: .public)")

        // Read loop
        isRunning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }

            let jsonDecoder = JSONDecoder()

            while self.isRunning {
                // Open blocks until a writer connects
                guard let fileHandle = FileHandle(forReadingAtPath: self.fifoPath)
                else {
                    continue
                }

                // Read until writer closes (EOF)
                let data = fileHandle.readDataToEndOfFile()
                try? fileHandle.close()
                if data.isEmpty {
                    continue
                }

                // Parse the json
                let command: Command
                do {
                    command = try jsonDecoder.decode(Command.self, from: data)
                } catch {
                    logger.error("Failed to decode: \(error)")
                    continue
                }

                self.commandHandler(command)
            }
        }
    }

    public func stop() {
        isRunning = false
        unlink(fifoPath)
    }
}
