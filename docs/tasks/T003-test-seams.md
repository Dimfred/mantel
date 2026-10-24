# T003 Domain folders + WindowEnvironment test seams

Milestone: M0
Feature: none (refactor)

## AC

- `Sources/mantel/{Command,Server,Window,Terminal,Observer,Shared}/`, tests mirror under `Tests/MantelCoreTests/`
- Pure logic extracted: `CellFrame` (cell → pixel), `TerminalWindow.find(forPID:in:)` (window list parsing), `ProcessTree.firstAncestor` (injectable parent lookup)
- `WindowManager` gets system deps via `WindowEnvironment` (`.live` default), windows via `OverlayWindow` protocol
- Dead code removed: `WindowManager.getParentPID` (dup), `setCellSize` / `cellWidth` / `cellHeight` (unused)

## Verify

- `make check` green; app behaves the same apart from T005 fixes

## Notes

- `getTerminal` did a direct lookup then a walk starting with the same pid (double CGWindowList call); now one walk

## Commits
