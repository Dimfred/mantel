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

        let command = try decodeCommand(json)

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
            try decodeCommand(json)
        }
    }

    @Test func addCommandRequiresSnakeCaseTerminalPid() {
        let json = """
            {"action":"add","identifier":"p","terminalPid":1,"path":"/a","x":0,"y":0,"width":1,"height":1,"cols":1,"rows":1}
            """

        #expect(throws: DecodingError.self) {
            try decodeCommand(json)
        }
    }

    @Test func addCommandWithWrongFieldTypeFailsDecoding() {
        let json = """
            {"action":"add","identifier":"p","terminal_pid":1,"path":"/a","x":"0","y":0,"width":1,"height":1,"cols":1,"rows":1}
            """

        #expect(throws: DecodingError.self) {
            try decodeCommand(json)
        }
    }

    @Test func addCommandIgnoresUnknownFields() throws {
        let json = """
            {"action":"add","identifier":"p","terminal_pid":1,"path":"/a","x":0,"y":0,"width":1,"height":1,"cols":1,"rows":1,"extra":true}
            """

        guard case .add(let addCommand) = try decodeCommand(json) else {
            Issue.record("Expected add command")
            return
        }
        #expect(addCommand.identifier == "p")
    }

    @Test(arguments: ["remove", "hide", "show", "toggle"])
    func identifierCommandsDecode(action: String) throws {
        let command = try decodeCommand(#"{"action":"\#(action)","identifier":"preview"}"#)

        let decoded: (String, BaseCommand)?
        switch command {
        case .remove(let c): decoded = ("remove", c)
        case .hide(let c): decoded = ("hide", c)
        case .show(let c): decoded = ("show", c)
        case .toggle(let c): decoded = ("toggle", c)
        case .add, .clear: decoded = nil
        }

        let (name, base) = try #require(decoded)
        #expect(name == action)
        #expect(base.identifier == "preview")
    }

    @Test(arguments: ["remove", "hide", "show", "toggle"])
    func identifierCommandsWithoutIdentifierFail(action: String) {
        #expect(throws: DecodingError.self) {
            try decodeCommand(#"{"action":"\#(action)"}"#)
        }
    }

    @Test func clearCommandDecodesWithoutIdentifier() throws {
        guard case .clear = try decodeCommand(#"{"action":"clear"}"#) else {
            Issue.record("Expected clear command")
            return
        }
    }

    @Test(arguments: [
        #"{"action":"explode","identifier":"p"}"#,
        #"{"identifier":"p"}"#,
        #"{"action":"HIDE","identifier":"p"}"#,
        "[]",
        "",
    ])
    func invalidPayloadsFail(json: String) {
        #expect(throws: DecodingError.self) {
            try decodeCommand(json)
        }
    }
}
