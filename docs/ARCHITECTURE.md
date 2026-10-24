# Architecture

Overview only: what each domain is and how domains connect.
Details live only in `architecture/<domain>.md` (name = source folder), never duplicated here.
Aim < 80 lines.

## Overview

Swift package, two targets:

- `MantelCore` (library, `Sources/mantel/`): all logic, one folder per domain
- `mantel` (executable, `Sources/mantel-bin/`): thin entry point, accessory `NSApplication` (no dock icon)

## Data flow

```
client ──JSON──▶ /tmp/mantel.fifo ──▶ FifoServer (bg queue, decode Command)
  ──main.async──▶ WindowManager.handleCommand ──▶ MainActorQueue (one op per main turn)
  ──▶ execute: loadImage, findTerminal (TerminalWindow + ProcessTree), CellFrame
  ──▶ OverlayWindow (ImageWindow) updateFrame / orderAbove(terminal window number)

WindowObserver (AX move/resize) ─┐
FocusObserver (app activated)  ──┴▶ WindowManager ── afterSettle 16ms ──▶ reposition / re-order
```

## Cross-cutting

- Threads: `FifoServer` reads on a global utility queue; everything else is `@MainActor` (AppKit)
- Swift 6 language mode, strict concurrency; cross-thread callbacks are `@Sendable` and hop to the main actor
- System access (AppKit windows, CGWindowList, NSScreen, AX, NSWorkspace) goes through `WindowEnvironment` closures so `WindowManager` is unit-tested with fakes
- Startup: `mantel.swift` → `AppDelegate` creates `WindowManager` + `FifoServer`; FIFO create failure → terminate
- Errors: bad input / missing image / missing terminal → logged, command dropped, daemon keeps running
- Logging: `os.Logger` subsystem `com.dimfred.mantel` (`log stream --predicate 'subsystem == "com.dimfred.mantel"'`)
- Permissions: Accessibility (move / resize tracking); everything else needs none
- Performance: reposition within one frame (16ms settle delay), no polling

## Domains

- [command](architecture/command.md): JSON command protocol (`Command`, `AddCommand`)
- [server](architecture/server.md): FIFO reader
- [window](architecture/window.md): `WindowManager`, overlay windows, command queue
- [terminal](architecture/terminal.md): terminal window lookup, process tree walk, cell → pixel math
- [observer](architecture/observer.md): AX window move / resize + app focus observers
- [shared](architecture/shared.md): logger, constants
- [app](architecture/app.md): executable entry point
