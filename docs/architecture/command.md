# command

Source: `Sources/mantel/Command/`
Tests: `Tests/MantelCoreTests/Command/`

## Responsibility

Decode one JSON object into a typed `Command`.

## Key types / interfaces

- `Command`: enum, one case per `action` (`add`, `remove`, `hide`, `show`, `toggle`, `clear`); custom `init(from:)` switches on `action`
- `AddCommand`: full spec, `terminal_pid` snake case on the wire, `terminalPid` in Swift
- `BaseCommand` (`identifier` only), aliased as `RemoveCommand` / `HideCommand` / `ShowCommand` / `ToggleCommand`
- `ClearAll`: no fields

## Decisions

- Unknown fields ignored (forward compatible clients); unknown / wrong-case action → `DecodingError`
- Cells, not pixels, on the wire: clients only know the terminal grid

## Known gaps

- No version field; protocol changes must stay backwards compatible
