# Features

What the app is and does: the current target state, edited in place, never a changelog.
Written by the user (spec) or derived by Claude from the user's input at bootstrap.
Behavior change → update this file first, then plan tasks for it.

Grouped by area (`## <area>`, `### <sub area>`); each item = what the user sees / does.
Task files link here (`Feature: [..](../FEATURES.md#<anchor>)`), so rename headings only together with those links (`make docs-lint` catches broken ones).
Open questions marked `?` and listed in `docs/HUMAN_TODO.md`.

Mantel: macOS-only daemon that draws images in native borderless windows over a terminal (like ueberzugpp, simpler).
Clients (e.g. an `lf` previewer) send JSON commands; positions are given in terminal cells.
Non-goals: cross-platform, App Store, Sixel / Kitty / iTerm2 protocols (native windows only).

## IPC

### FIFO

- Daemon listens on `/tmp/mantel.fifo`; a stale file there is replaced at start, the FIFO is removed on quit
- One JSON command per writer (open, write, close), e.g. `echo '{"action":"hide","identifier":"preview"}' > /tmp/mantel.fifo`
- Invalid JSON / unknown action / missing field → logged and skipped, the daemon keeps reading
- Commands are executed in the order they arrive
- Several writers in quick succession never lose a command (T010)
- ? Second transport via unix socket (`SocketServer` exists but is not wired, H1)

### Commands

- `add`: `identifier`, `terminal_pid`, `path`, `x`, `y`, `width`, `height` (cells), `cols`, `rows` (terminal grid) → image shown; same `identifier` again → image and position replaced in place
- `remove`: image disappears, `identifier` can be added again later
- `hide` / `show` / `toggle`: visibility only, image and position kept
- `show` / `toggle` on a removed or unknown `identifier` → nothing happens
- `clear`: every image disappears
- Commands for an unknown `identifier` are ignored

## Overlay

### Placement

- Position and size in terminal cells; cell size = terminal window size / `cols`, `rows`
- Image scaled proportionally into its frame, transparent background
- Mouse clicks pass through to the terminal
- `cols` or `rows` ≤ 0 → `add` rejected (logged)

### Z-order

- Image sits just above its terminal window, never above other apps' windows covering the terminal
- `show` / `toggle` bring it back above its terminal only
- Any app gets focus → visible images are re-ordered above their terminals; hidden ones stay hidden
- Visible on all spaces

### Window lifecycle

- Windows are reused per `identifier`; only `clear` destroys them (crash workaround)
- Long-running daemon does not leak windows for removed identifiers (T013)

## Terminal tracking

### Discovery

- `terminal_pid` may be the terminal or any descendant (shell, `lf`, …) → mantel walks up the process tree (max 10 hops) to the first process owning an on-screen window
- Only regular windows (layer 0) count, not menus / tooltips (T012)
- ? Terminal app with several windows in one process: which window hosts the shell (H2)

### Move and resize

- Terminal moved or resized → its images follow (needs Accessibility permission, prompted on first `add`)
- Hidden images follow too but stay hidden

### Multi-monitor

- Coordinates relative to the primary screen, so terminals on screens above / left / right of it work

## Service

### Install

- `make install` → binary in `/usr/local/bin`, LaunchAgent `com.dimfred.mantel` started at login; `make uninstall` reverts

### Release

- `make release`: bump patch in `VERSION`, GitHub release with the arm64 binary, update the brew tap formula
