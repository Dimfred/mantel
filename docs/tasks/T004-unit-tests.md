# T004 Unit tests for command, server, window, terminal

Milestone: M0
Feature: [Commands](../FEATURES.md#commands), [FIFO](../FEATURES.md#fifo), [Placement](../FEATURES.md#placement), [Discovery](../FEATURES.md#discovery), [Move and resize](../FEATURES.md#move-and-resize), [Multi-monitor](../FEATURES.md#multi-monitor)

## AC

- Command: every action decodes, missing / wrong-typed fields, unknown / wrong-case action, unknown fields ignored
- CellFrame: origin, offset + size, full grid, fractional cells, screen above primary, invalid grid
- TerminalWindow parsing: match by pid, first match wins, incomplete bounds / missing number skipped
- ProcessTree: walk, stop at launchd / unknown parent / max hops; real `parentPID` vs `getppid`
- WindowManager (fakes): add / reuse / failures, observers once per terminal + retry, hide / show / toggle / remove / clear, reposition (own terminal only, hidden stay hidden), focus re-order, queued order
- MainActorQueue: order, async, nested enqueue, one op per main turn, restart after drain
- FifoServer (real FIFO in temp dir): create, dispatch, sequential order, invalid JSON skipped, stale file replaced, stop unlinks, missing dir throws

## Verify

- `make test`: 62 tests, stable over repeated runs

## Notes

- Not unit-tested (need window server / AX trust): `ImageWindow`, `WindowObserver`, `FocusObserver`, `mantel-bin` → `docs/CHECKLIST.md`
- Writing the FIFO tests surfaced the write race (T010)

## Commits
