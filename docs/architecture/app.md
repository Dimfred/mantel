# app

Source: `Sources/mantel-bin/`

## Responsibility

Executable entry point: accessory `NSApplication`, SIGINT / SIGTERM → terminate, wires `FifoServer` → `WindowManager`.

## Key types / interfaces

- `Mantel.main()`: activation policy `.accessory`, runs the app
- `AppDelegate`: starts `FifoServer(fifoPath: defaultFifoPath)`, hops each command to main, stops the server on terminate

## Decisions

- Stays thin; no logic that needs tests lives here

## Known gaps

- FIFO path not configurable (flag / env)
