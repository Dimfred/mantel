# T006 Baseline: features built before bootstrap

Milestone: M0
Feature: [Install](../FEATURES.md#install), [Release](../FEATURES.md#release), [Window lifecycle](../FEATURES.md#window-lifecycle), [Z-order](../FEATURES.md#z-order)

## AC

- Records what existed before the template was adopted (commits up to `4be3ece`): FIFO daemon, commands, placement, AX move / resize tracking, focus re-order, multi-monitor Y flip, window reuse, launchd install, GitHub + brew release

## Verify

- none (bookkeeping, keeps `make feature-gaps` honest)

## Notes

- Loop never runs `make install`, `make uninstall` or `make release*` (sudo, push, publishes)

## Commits

- `4be3ece` and earlier
