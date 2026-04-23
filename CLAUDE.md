# Mantel

Terminal image overlay daemon for macOS using AppKit.

## Known Issues

- **Window cleanup causes crashes**: Calling `NSWindow.close()` on image windows and then creating new ones with the same identifier causes `objc_release` crashes during autorelease pool cleanup. Current workaround is to never destroy windows - just hide them and reuse on next add. This causes windows to pile up over time. Needs proper fix.

## Architecture

- `mantel.swift` - Entry point, sets up NSApplication and FIFO server
- `FifoServer.swift` - Reads JSON commands from `/tmp/mantel.fifo`
- `WindowManager.swift` - Manages image windows, processes commands via queue
- `ImageWindow.swift` - Wrapper around NSWindow for displaying images
- `TerminalWindow.swift` - Finds terminal window bounds via CGWindowList
- `Command.swift` - JSON command structure (add/remove/hide/show/toggle/clear)
