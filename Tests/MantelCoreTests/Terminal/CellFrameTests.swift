import CoreGraphics
import Testing

@testable import MantelCore

@Suite("CellFrame")
struct CellFrameTests {
    let terminal = CGRect(x: 100, y: 50, width: 800, height: 480)

    @Test func originCellMapsToTerminalTopLeft() throws {
        let command = AddCommand.fixture(x: 0, y: 0, width: 1, height: 1, cols: 80, rows: 24)

        let frame = try CellFrame.frame(for: command, terminalBounds: terminal, primaryScreenHeight: 1000)

        #expect(frame == CGRect(x: 100, y: 1000 - 50 - 20, width: 10, height: 20))
    }

    @Test func offsetAndSizeScaleWithCellSize() throws {
        let command = AddCommand.fixture(x: 10, y: 2, width: 40, height: 10, cols: 80, rows: 24)

        let frame = try CellFrame.frame(for: command, terminalBounds: terminal, primaryScreenHeight: 1000)

        #expect(frame == CGRect(x: 200, y: 710, width: 400, height: 200))
    }

    @Test func fullGridCoversWholeTerminal() throws {
        let command = AddCommand.fixture(x: 0, y: 0, width: 80, height: 24, cols: 80, rows: 24)

        let frame = try CellFrame.frame(for: command, terminalBounds: terminal, primaryScreenHeight: 1000)

        #expect(frame == CGRect(x: 100, y: 1000 - 50 - 480, width: 800, height: 480))
    }

    @Test func fractionalCellSizeIsKept() throws {
        let command = AddCommand.fixture(x: 1, y: 1, width: 1, height: 1, cols: 3, rows: 7)
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        let frame = try CellFrame.frame(for: command, terminalBounds: bounds, primaryScreenHeight: 100)

        #expect(abs(frame.width - 100.0 / 3.0) < 1e-9)
        #expect(abs(frame.height - 100.0 / 7.0) < 1e-9)
        #expect(abs(frame.origin.x - 100.0 / 3.0) < 1e-9)
    }

    @Test func terminalOnSecondaryScreenAboveGivesYAbovePrimary() throws {
        let above = CGRect(x: 0, y: -1080, width: 800, height: 480)
        let command = AddCommand.fixture(x: 0, y: 0, width: 1, height: 1, cols: 80, rows: 24)

        let frame = try CellFrame.frame(for: command, terminalBounds: above, primaryScreenHeight: 1000)

        #expect(frame.origin.y == CGFloat(2060))
    }

    @Test(arguments: [(0, 24), (80, 0), (-1, 24), (80, -5)])
    func invalidGridThrows(cols: Int, rows: Int) {
        let command = AddCommand.fixture(cols: cols, rows: rows)

        #expect(throws: CellFrameError.invalidGrid(cols: cols, rows: rows)) {
            try CellFrame.frame(for: command, terminalBounds: terminal, primaryScreenHeight: 1000)
        }
    }
}
