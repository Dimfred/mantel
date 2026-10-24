---
name: decisions
description: Choices taken without the user (spec left them open); user may revisit any of them
metadata:
  type: project
---

Log of decisions Claude took alone.
Each: date, decision, why, how to undo.
User (bits, 2026-10-21): "remember decision points you took, we change that later if we have to".

- 2026-10-24 Lint via bundled `swift format` (4 spaces, 120 cols, no force unwrap / try / IUO) + `-warnings-as-errors`. Why: no new dep, matches existing style. Undo: edit `.swift-format` / `make lint`
- 2026-10-24 Tests stay in `Tests/MantelCoreTests/` (SPM convention), not lowercase `tests/`; Swift Testing over XCTest (already used). Undo: move dir + `Package.swift` path
- 2026-10-24 Sources split into domain folders (`Command`, `Server`, `Window`, `Terminal`, `Observer`, `Shared`); module name unchanged
- 2026-10-24 `WindowManager` system deps behind `WindowEnvironment` closures (not protocols per dep). Why: one struct, trivial fakes. Undo: inline `.live`
- 2026-10-24 `show` / `toggle` order above the terminal instead of `orderFront`; reposition / focus skip hidden windows; `show` after `remove` is a no-op. Why: old behavior covered other apps / revived hidden images (T005)
- 2026-10-24 `add` with `cols` / `rows` ≤ 0 rejected instead of dividing by zero
- 2026-10-24 Removed unused `setCellSize` / `cellWidth` / `cellHeight` and duplicate `getParentPID` from `WindowManager`
- 2026-10-24 `FIFO_PATH` → `defaultFifoPath` (lint rule)
- 2026-10-24 `FifoServerTests` invalid-JSON test sleeps 200ms between writes until T010 fixes the write race
- 2026-10-24 Old `CONTEXT.md` (socket-era spec) folded into `docs/FEATURES.md` / `docs/ARCHITECTURE.md` and removed; old `CLAUDE.md` features / known issues / TODO moved to docs
- 2026-10-24 M1 task ids start at T010 (T007–T009 unused)
