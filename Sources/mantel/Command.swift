import Foundation

/// Actions that can be performed on image windows.
public enum Action: String, Decodable {
    case add  // Create/update image at position
    case remove  // Hide image (keeps window for reuse)
    case hide  // Hide without clearing image
    case show  // Show hidden window
    case toggle  // Toggle visibility
    case clear  // Destroy all windows
}

public struct BaseCommand: Decodable, Sendable {
    /// Unique ID for this window (e.g. "preview")
    public let identifier: String
}
public typealias RemoveCommand = BaseCommand
public typealias HideCommand = BaseCommand
public typealias ShowCommand = BaseCommand
public typealias ToggleCommand = BaseCommand

/// Fully specified image creation/update command.
public struct AddCommand: Decodable, Sendable {
    /// Unique ID for this window (e.g. "preview")
    public let identifier: String
    /// PID of terminal process - used to find terminal window bounds
    public let terminalPid: pid_t
    /// Path to image file
    public let path: String
    /// Position in terminal cells (0,0 = top-left)
    public let x: Int
    public let y: Int
    /// Size in terminal cells
    public let width: Int
    public let height: Int
    /// Terminal dimensions for calculating cell size
    public let cols: Int
    public let rows: Int

    private enum CodingKeys: String, CodingKey {
        case identifier
        case terminalPid = "terminal_pid"
        case path
        case x, y, width, height
        case cols, rows
    }
}
public struct ClearAll: Decodable, Sendable {}

public enum Command: Decodable, Sendable {
    case add(AddCommand)
    case remove(RemoveCommand)
    case hide(HideCommand)
    case show(ShowCommand)
    case toggle(ToggleCommand)
    case clear(ClearAll)

    private enum CodingKeys: String, CodingKey {
        case action
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let action = try container.decode(Action.self, forKey: .action)

        switch action {
        case .add:
            self = .add(try AddCommand(from: decoder))
        case .remove:
            self = .remove(try RemoveCommand(from: decoder))
        case .hide:
            self = .hide(try HideCommand(from: decoder))
        case .show:
            self = .show(try ShowCommand(from: decoder))
        case .toggle:
            self = .toggle(try ToggleCommand(from: decoder))
        case .clear:
            self = .clear(try ClearAll(from: decoder))
        }
    }
}
