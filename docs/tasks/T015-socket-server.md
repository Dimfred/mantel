# T015 SocketServer: wire or delete

Milestone: M1
Feature: [FIFO](../FEATURES.md#fifo)

## AC

- User decision (H1): delete `Sources/mantel/Server/SocketServer.swift`, or wire it as a second transport (`/tmp/mantel-$PID.sock` per the old CONTEXT.md) with tests

## Verify

- Delete: `make check` green, no references left
- Wire: socket integration tests like `FifoServerTests`

## Notes

- Was compiled but never started; FIFO is the only transport clients use
- User (2026-10-24): "delete it the server" → deleted

## Commits
