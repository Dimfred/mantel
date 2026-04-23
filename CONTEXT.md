# Mantel

A macOS-native image overlay tool for terminals, written in Swift. Like ueberzugpp but simpler and macOS-only.

## Core Features

- Render images in floating borderless windows over the terminal
- Persistent windows that can be toggled/hidden/shown
- Unix domain socket for IPC (`/tmp/mantel-$PID.sock`)
- JSON command protocol (ueberzugpp-compatible where sensible)

## Architecture

### Window Discovery
Use `CGWindowListCopyWindowInfo` to find terminal window:
1. Get parent process PID (the terminal)
2. Query all windows, filter by owning PID
3. Extract `kCGWindowBounds` for positioning

No special permissions required.

### IPC Protocol
Unix domain socket, unidirectional (client → mantel).

Commands:
```json
{"action":"add","identifier":"preview","path":"/path/img.png","x":0,"y":0,"width":10,"height":10}
{"action":"remove","identifier":"preview"}
{"action":"hide","identifier":"preview"}
{"action":"show","identifier":"preview"}
{"action":"toggle","identifier":"preview"}
```

Coordinates are in terminal cells (columns/rows), converted to pixels using font metrics.

### Components
1. **Socket listener** - accepts JSON commands
2. **Window manager** - maps identifiers → NSWindow instances
3. **Image renderer** - NSImage + NSImageView in borderless NSWindow
4. **Coordinate translator** - terminal cells → screen pixels

### Window Behavior
- Borderless, non-activating (doesn't steal focus)
- Stays above terminal but below other apps
- Handles terminal resize/move (re-query window bounds)

## Tech Stack
- Swift
- AppKit (NSWindow, NSImage)
- Foundation (Unix sockets or Network.framework)
- Core Graphics (CGWindowListCopyWindowInfo)

## Non-Goals
- Cross-platform support
- App Store distribution
- Sixel/Kitty/iTerm2 protocols (native windows only)
