# T011 FIFO lifecycle: deleted FIFO, stop, isRunning race

Milestone: M1
Feature: [FIFO](../FEATURES.md#fifo)

## AC

- FIFO deleted while running → recreated (or error logged once), no busy loop
- `stop()` ends the read loop promptly (no thread left blocked in `open()`)
- `isRunning` access synchronized (lock / atomic), no `@unchecked Sendable` hole for it

## Verify

- Tests: delete FIFO path while running → server recovers / logs, CPU not spinning (loop iterations bounded); stop → read loop exits within a timeout

## Notes

- Today: `FileHandle(forReadingAtPath:)` returns nil for a missing path → `continue` → 100% CPU
- Likely solved together with T010's single `O_RDWR` fd: `stop()` can close the fd / write a wake byte

## Commits
