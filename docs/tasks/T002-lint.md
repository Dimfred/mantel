# T002 Lint: swift format + warnings as errors

Milestone: M0
Feature: none (tooling)

## AC

- `make lint` = `swift format format -i` → `swift format lint --strict` → `swift build --build-tests -Xswiftc -warnings-as-errors`
- `.swift-format`: 4 spaces, 120 cols, `NeverForceUnwrap` / `NeverUseForceTry` / `NeverUseImplicitlyUnwrappedOptionals` on
- Whole codebase formatted and lint clean

## Verify

- `make lint` green, second run changes nothing

## Notes

- `swift format` ships with the toolchain, no new dependency; swiftlint / swiftformat not installed and not needed
- `FIFO_PATH` → `defaultFifoPath` (lowerCamelCase rule)

## Commits
