# T013 Close removed windows without crash

Milestone: M1
Feature: [Window lifecycle](../FEATURES.md#window-lifecycle)

## AC

- `remove` releases its window; re-adding the same `identifier` creates a fresh one, no `objc_release` crash
- Window count stays flat over many add / remove cycles

## Verify

- `WindowManagerTests`: remove → `destroy` called, next add → new window
- Manual (`[?]`, add to `docs/CHECKLIST.md`): script 500 add / remove cycles with the same id against the running daemon, no crash, window count stable

## Notes

- Suspected cause: code-created `NSWindow` has `isReleasedWhenClosed = true`, so `close()` releases it and ARC releases again → over-release during autorelease pool pop. Set `isReleasedWhenClosed = false` in `ImageWindow.init`
- Update `CLAUDE.md` / `docs/architecture/window.md` known gaps once fixed

## Commits
