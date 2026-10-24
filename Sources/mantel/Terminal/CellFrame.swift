import CoreGraphics

enum CellFrameError: Error, Equatable {
    case invalidGrid(cols: Int, rows: Int)
}

/// Converts terminal cell coordinates to an AppKit screen frame.
enum CellFrame {
    /// Terminal uses (0,0) at top-left, AppKit uses bottom-left of the primary screen, so Y is flipped.
    /// Cell size is derived from the terminal bounds and the reported grid size.
    static func frame(
        for command: AddCommand,
        terminalBounds: CGRect,
        primaryScreenHeight: CGFloat
    ) throws -> CGRect {
        guard command.cols > 0, command.rows > 0 else {
            throw CellFrameError.invalidGrid(cols: command.cols, rows: command.rows)
        }

        let cellW = terminalBounds.width / CGFloat(command.cols)
        let cellH = terminalBounds.height / CGFloat(command.rows)

        let pixelX = terminalBounds.origin.x + CGFloat(command.x) * cellW
        let pixelWidth = CGFloat(command.width) * cellW
        let pixelHeight = CGFloat(command.height) * cellH

        let imageTopInCGCoords = terminalBounds.origin.y + CGFloat(command.y) * cellH
        let pixelY = primaryScreenHeight - imageTopInCGCoords - pixelHeight

        return CGRect(x: pixelX, y: pixelY, width: pixelWidth, height: pixelHeight)
    }
}
