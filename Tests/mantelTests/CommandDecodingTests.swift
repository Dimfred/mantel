import Foundation
import Testing
@testable import MantelCore

@Suite("Command decoding")
struct CommandDecodingTests {
    @Test func addCommandDecodesRequiredFields() throws {
        let json = """
            {
                "action": "add",
                "identifier": "preview",
                "terminal_pid": 1234,
                "path": "/tmp/img.png",
                "x": 10,
                "y": 2,
                "width": 50,
                "height": 30,
                "cols": 80,
                "rows": 24
            }
            """

        let command = try JSONDecoder().decode(Command.self, from: Data(json.utf8))

        guard case .add(let addCommand) = command else {
            Issue.record("Expected add command")
            return
        }

        #expect(addCommand.identifier == "preview")
        #expect(addCommand.terminalPid == 1234)
        #expect(addCommand.path == "/tmp/img.png")
        #expect(addCommand.x == 10)
        #expect(addCommand.y == 2)
        #expect(addCommand.width == 50)
        #expect(addCommand.height == 30)
        #expect(addCommand.cols == 80)
        #expect(addCommand.rows == 24)
    }

    @Test func addCommandMissingRequiredFieldsFailsDecoding() {
        let json = """
            {
                "action": "add",
                "identifier": "preview"
            }
            """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Command.self, from: Data(json.utf8))
        }
    }

    @Test func hideCommandDecodesIdentifier() throws {
        let json = """
            {
                "action": "hide",
                "identifier": "preview"
            }
            """

        let command = try JSONDecoder().decode(Command.self, from: Data(json.utf8))

        guard case .hide(let hideCommand) = command else {
            Issue.record("Expected hide command")
            return
        }

        #expect(hideCommand.identifier == "preview")
    }

    @Test func clearCommandDecodesWithoutIdentifier() throws {
        let json = """
            {
                "action": "clear"
            }
            """

        let command = try JSONDecoder().decode(Command.self, from: Data(json.utf8))

        guard case .clear = command else {
            Issue.record("Expected clear command")
            return
        }
    }
}
