---
name: stack-choice
description: Mantel stack (fixed before template adoption) - Swift 6 SPM AppKit, swift format, Swift Testing, no third-party deps
metadata:
  type: project
---

Swift package (tools 6.3, Swift 6 language mode), macOS 13+, AppKit / CoreGraphics / ApplicationServices only.
Lint: `swift format` from the toolchain (`.swift-format`), typecheck via `swift build --build-tests -Xswiftc -warnings-as-errors`.
Tests: Swift Testing (`import Testing`), `Tests/MantelCoreTests/` mirrors `Sources/mantel/`.
No third-party dependencies.

**Why:** project existed before adopting auto-template (2026-10-24); stack was not re-chosen, only tooling added without new deps.
**How to apply:** any SPM dependency → `Blocked` + `docs/HUMAN_TODO.md`. Related: [[decisions]], [[lint-single-target]].
