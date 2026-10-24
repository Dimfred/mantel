# terminal

Source: `Sources/mantel/Terminal/`
Tests: `Tests/MantelCoreTests/Terminal/`

## Responsibility

Find the terminal window for a pid and convert cell coordinates to an AppKit frame.

## Key types / interfaces

- `TerminalWindow`: `bounds` (CG coords, y down from primary top), `pid`, `windowNumber`
  - `find(forPID:)` live CGWindowList (on-screen, no desktop elements); `find(forPID:in:)` pure parser
  - `findOwningTerminal(pid:)`: process tree walk using `find(forPID:)`
- `ProcessTree.firstAncestor(startingFrom:maxHops:parentOf:matching:)`: generic walk, stops at pid ≤ 1, unknown parent or `maxHops` (10); `parentPID(of:)` via `sysctl`, nil for missing pids
- `CellFrame.frame(for:terminalBounds:primaryScreenHeight:)`: throws `CellFrameError.invalidGrid` for cols / rows ≤ 0

## Decisions

- Y flip uses the primary screen (origin 0,0) height, matches CGWindowList's global coordinate space on multi-monitor setups
- Lookups always fresh (no cache), terminal may have moved since the last command

## Known gaps

- First on-screen window of the pid wins, no layer filter (menus, tooltips) (T012)
- Multi-window terminals (one process, many windows): frontmost window wins, may not be the one hosting the shell; accepted by the user, parked in `Later`
- Cell size includes window chrome (title bar, padding) since bounds are the whole window
