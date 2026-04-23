import Foundation

/// Reads JSON commands from a named pipe (FIFO).
/// Runs a background read loop and dispatches parsed commands to handler.
final class FifoServer: @unchecked Sendable {
    private let fifoPath: String
    private var isRunning = false
    private let commandHandler: @Sendable (Command) -> Void

    init(fifoPath: String, commandHandler: @escaping @Sendable (Command) -> Void) {
        self.fifoPath = fifoPath
        self.commandHandler = commandHandler
    }

    deinit {
        stop()
    }

    /// Create FIFO and start background read loop.
    func start() throws {
        // Remove stale FIFO if exists
        unlink(fifoPath)

        let result = mkfifo(fifoPath, 0o666)
        guard result == 0 else {
            throw FifoError.createFailed(errno: errno)
        }

        isRunning = true
        print("Listening on \(fifoPath)")

        readLoop()
    }

    func stop() {
        isRunning = false
        unlink(fifoPath)
    }

    /// Background loop that reads from FIFO.
    /// FIFO blocks until a writer connects, then reads all data until EOF.
    /// Each line is parsed as a JSON Command.
    private func readLoop() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }

            while self.isRunning {
                // Open blocks until a writer connects
                guard let fileHandle = FileHandle(forReadingAtPath: self.fifoPath) else {
                    if self.isRunning {
                        usleep(10000)
                    }
                    continue
                }

                // Read until writer closes (EOF)
                let data = fileHandle.readDataToEndOfFile()
                try? fileHandle.close()

                if data.isEmpty { continue }

                // Parse each line as separate JSON command
                let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") ?? []
                let decoder = JSONDecoder()

                for line in lines {
                    print("Raw JSON: \(line)")
                    guard let lineData = line.data(using: .utf8) else { continue }
                    do {
                        let command = try decoder.decode(Command.self, from: lineData)
                        self.commandHandler(command)
                    } catch {
                        print("Failed to decode: \(error)")
                    }
                }
            }
        }
    }
}

enum FifoError: Error {
    case createFailed(errno: Int32)
}
