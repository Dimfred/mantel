# server

Source: `Sources/mantel/Server/`
Tests: `Tests/MantelCoreTests/Server/`

## Responsibility

Receive raw command bytes from clients, decode, hand `Command` to a `@Sendable` handler.

## Key types / interfaces

- `FifoServer(fifoPath:commandHandler:)`: `start()` (unlink + `mkfifo 0666`, throws `FifoError.createFailed(errno:)`), `stop()` (unlink)
- Read loop on a global utility queue: open (blocks until a writer) → read to EOF → close → decode → handler

## Decisions

- FIFO only, no socket: clients are shell scripts, `echo … > fifo` is the simplest client; unused `SocketServer` deleted (T015)
- Handler is called off-main; the app hops to main before touching `WindowManager`

## Known gaps

- Write race: a writer that opens between the reader's EOF and its `close()` gets `SIGPIPE` / its data is dropped (T010). Tests wait for each message before writing the next
- One command per open / close; two JSON objects in one write fail to decode (T010)
- FIFO deleted while running → `FileHandle(forReadingAtPath:)` returns nil → busy loop (T011)
- `stop()` leaves the reader thread blocked in `open()`; `isRunning` is an unsynchronized `var` (T011)
