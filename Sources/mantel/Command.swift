import Foundation

/// Actions that can be performed on image windows
enum Action: String, Codable {
    case add      // Create/update image at position
    case remove   // Hide image (keeps window for reuse)
    case hide     // Hide without clearing image
    case show     // Show hidden window
    case toggle   // Toggle visibility
    case clear    // Destroy all windows
}

/// JSON command received via FIFO.
/// Example: {"action":"add","identifier":"preview","terminal_pid":1234,"path":"/tmp/img.png","x":10,"y":2,"width":50,"height":30,"cols":80,"rows":24}
struct Command: Codable {
    let action: Action
    /// Unique ID for this window (e.g. "preview")
    let identifier: String
    /// PID of terminal process - used to find terminal window bounds
    var terminalPid: pid_t?
    /// Path to image file
    var path: String?
    /// Position in terminal cells (0,0 = top-left)
    var x: Int?
    var y: Int?
    /// Size in terminal cells
    var width: Int?
    var height: Int?
    /// Terminal dimensions for calculating cell size
    var cols: Int?
    var rows: Int?

    enum CodingKeys: String, CodingKey {
        case action
        case identifier
        case terminalPid = "terminal_pid"
        case path
        case x, y, width, height
        case cols, rows
    }
}
