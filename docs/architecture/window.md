# window

Source: `Sources/mantel/Window/`
Tests: `Tests/MantelCoreTests/Window/` (fakes in `Tests/MantelCoreTests/Helpers/`)

## Responsibility

Own all overlay windows: execute commands, keep images placed and z-ordered above their terminal.

## Key types / interfaces

- `WindowManager` (`@MainActor`, public): `handleCommand(_:)` queues; `execute(_:)` runs one command (internal, used by tests); `handleTerminalWindowChange(pid:)`, `handleFocusChange(activePid:)`
- State: `windows[identifier]` (kept after `remove` for reuse), `lastAddCommands[identifier]` (absent = removed), observer tokens per terminal pid + one focus observer
- `OverlayWindow` protocol: `isVisible`, `orderAbove(windowNumber:)`, `hide`, `close`, `destroy`, `updateFrame`, `updateImage`
- `ImageWindow`: AppKit impl, borderless transparent `NSWindow`, `.normal` level, ignores mouse, all spaces
- `WindowEnvironment`: closures for `loadImage`, `findTerminal`, `primaryScreenHeight`, `makeWindow`, `observeTerminal`, `observeFocus`, `afterSettle`; `.live` wires the real system
- `MainActorQueue`: FIFO of main-actor ops, one per `DispatchQueue.main` turn

## Decisions

- One command per main-queue turn: gives AppKit time for window cleanup between ops (crash mitigation)
- `show` / `toggle` use `orderAbove(terminal)`, never `orderFront` (that would cover other apps)
- Reposition / focus re-order skip hidden windows: `order(_:relativeTo:)` would make them visible
- 16ms `afterSettle` before reading CGWindowList after AX / focus events, bounds and z-order lag behind
- Cell size derived from terminal bounds / grid on each add, no fixed cell size

## Known gaps

- Windows never closed: `NSWindow.close()` + re-create with same id crashed in `objc_autoreleasePoolPop`, so `remove` only hides; windows pile up (T013). Likely cause: `isReleasedWhenClosed` defaults to true for code-created windows
- Terminal observers never stopped, also when its last image is removed or the terminal quits (T014)
- `ImageWindow` itself is not unit-tested (needs a window server); covered by `docs/CHECKLIST.md`
