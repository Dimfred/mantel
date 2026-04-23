# Mantel

Terminal image overlay daemon for macOS using AppKit.

## Features

- **RPC via FIFO**: JSON commands sent to `/tmp/mantel.fifo`
- **Commands**: add, remove, hide, show, toggle, clear
- **Cell-based positioning**: Image position/size specified in terminal cells, converted to pixels
- **Occlusion via z-level**: Images use `.normal` window level and `orderAbove(relativeTo:)` to stay just above their terminal - macOS handles occlusion automatically
- **Window move/resize tracking**: Accessibility API (`AXObserver`) watches terminal for `kAXWindowMovedNotification`, `kAXWindowResizedNotification`
- **Focus tracking**: `NSWorkspace.didActivateApplicationNotification` triggers re-ordering of images above their terminals
- **Multi-monitor support**: Coordinate conversion uses primary screen (origin 0,0) for Y-flip
- **Window reuse**: Windows are hidden/reused rather than destroyed to avoid crashes

## Known Issues

- **Window cleanup causes crashes**: Calling `NSWindow.close()` on image windows and then creating new ones with the same identifier causes `objc_release` crashes during autorelease pool cleanup. Current workaround is to never destroy windows - just hide them and reuse on next add. This causes windows to pile up over time. Needs proper fix.
- **16ms delay for state sync**: After window events, we delay 16ms before querying CGWindowList to let AppKit update bounds/z-order

## Architecture

- `mantel.swift` - Entry point, sets up NSApplication and FIFO server
- `FifoServer.swift` - Reads JSON commands from `/tmp/mantel.fifo`
- `WindowManager.swift` - Manages image windows, command queue, coordinates observers
- `ImageWindow.swift` - NSWindow wrapper with `orderAbove(windowNumber:)` for z-ordering
- `TerminalWindow.swift` - Finds terminal window bounds + windowNumber via CGWindowList
- `WindowObserver.swift` - Accessibility API observer for window move/resize events
- `FocusObserver.swift` - NSWorkspace observer for app focus changes
- `Command.swift` - JSON command structure
