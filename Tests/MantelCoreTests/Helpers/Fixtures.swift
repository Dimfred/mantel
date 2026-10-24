import CoreGraphics
import Foundation

@testable import MantelCore

extension AddCommand {
    static func fixture(
        identifier: String = "preview",
        terminalPid: pid_t = 100,
        path: String = "/img.png",
        x: Int = 0,
        y: Int = 0,
        width: Int = 10,
        height: Int = 5,
        cols: Int = 80,
        rows: Int = 24
    ) -> AddCommand {
        AddCommand(
            identifier: identifier, terminalPid: terminalPid, path: path,
            x: x, y: y, width: width, height: height, cols: cols, rows: rows)
    }
}

func decodeCommand(_ json: String) throws -> Command {
    try JSONDecoder().decode(Command.self, from: Data(json.utf8))
}
