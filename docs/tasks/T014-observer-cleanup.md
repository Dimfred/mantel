# T014 Stop observers for terminals without images

Milestone: M1
Feature: [Move and resize](../FEATURES.md#move-and-resize)

## AC

- Last image of a terminal removed / `clear` → its `WindowObserver` stopped and dropped
- Terminal process gone (lookup fails on reposition) → its images removed, observer dropped
- Focus observer stopped when no images are left, restarted on next `add`

## Verify

- `WindowManagerTests` with the fake env: observer token released (weak ref nil) after remove / clear; re-add starts a new one

## Notes

## Commits
