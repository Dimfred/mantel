# T012 Terminal lookup: regular windows only

Milestone: M1
Feature: [Discovery](../FEATURES.md#discovery)

## AC

- `TerminalWindow.find(forPID:in:)` only accepts windows with `kCGWindowLayer == 0`
- Zero-size windows skipped

## Verify

- `TerminalWindowTests`: menu / tooltip window (layer ≠ 0) before the real one → real one picked; zero-size skipped

## Notes

- Today the first on-screen window of the pid wins; an open menu or tooltip of the terminal can become the anchor

## Commits
