# T005 Visibility keeps z-order: show / toggle / hidden on move

Milestone: M0
Feature: [Z-order](../FEATURES.md#z-order), [Move and resize](../FEATURES.md#move-and-resize), [Commands](../FEATURES.md#commands), [Placement](../FEATURES.md#placement)

## AC

- `show` / `toggle` order the image above its terminal (was `orderFront` → above every app)
- `show` / `toggle` after `remove` do nothing (was: empty window ordered in)
- Terminal move / resize updates hidden images' frames without showing them (`order(_:relativeTo:)` makes a window visible)
- Focus change re-orders only visible images
- `cols` / `rows` ≤ 0 rejects the `add` (was: division by zero → infinite frame)

## Verify

- Unit tests in `Tests/MantelCoreTests/Window/WindowManagerTests.swift`, `Terminal/CellFrameTests.swift`
- Manual: `docs/CHECKLIST.md` → T005

## Notes

## Commits
