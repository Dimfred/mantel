import Foundation

final class SocketServer: @unchecked Sendable {
    private let socketPath: String
    private var serverSocket: Int32 = -1
    private var isRunning = false
    private let commandHandler: @Sendable (Command) -> Void

    init(socketPath: String, commandHandler: @escaping @Sendable (Command) -> Void) {
        self.socketPath = socketPath
        self.commandHandler = commandHandler
    }

    deinit {
        stop()
    }

    func start() throws {
        unlink(socketPath)

        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            throw SocketError.createFailed
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)

        let pathBytes = socketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
            throw SocketError.pathTooLong
        }

        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { dest in
                for (i, byte) in pathBytes.enumerated() {
                    dest[i] = byte
                }
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult == 0 else {
            close(serverSocket)
            throw SocketError.bindFailed
        }

        guard listen(serverSocket, 5) == 0 else {
            close(serverSocket)
            throw SocketError.listenFailed
        }

        isRunning = true
        logger.info("Listening on \(self.socketPath, privacy: .public)")

        acceptLoop()
    }

    func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        unlink(socketPath)
    }

    private func acceptLoop() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }

            while self.isRunning {
                var clientAddr = sockaddr_un()
                var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

                let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                        accept(self.serverSocket, sockaddrPtr, &clientAddrLen)
                    }
                }

                guard clientSocket >= 0 else {
                    if self.isRunning {
                        logger.error("Accept failed")
                    }
                    continue
                }

                self.handleClient(clientSocket)
            }
        }
    }

    private func handleClient(_ clientSocket: Int32) {
        defer { close(clientSocket) }

        var buffer = [UInt8](repeating: 0, count: 4096)
        var data = Data()

        while true {
            let bytesRead = read(clientSocket, &buffer, buffer.count)
            if bytesRead <= 0 {
                break
            }
            data.append(contentsOf: buffer[0..<bytesRead])
        }

        let lines = String(data: data, encoding: .utf8)?.split(separator: "\n") ?? []
        let decoder = JSONDecoder()

        for line in lines {
            guard let lineData = line.data(using: .utf8) else { continue }
            do {
                let command = try decoder.decode(Command.self, from: lineData)
                commandHandler(command)
            } catch {
                logger.error("Failed to decode command: \(error)")
            }
        }
    }
}

enum SocketError: Error {
    case createFailed
    case pathTooLong
    case bindFailed
    case listenFailed
}
