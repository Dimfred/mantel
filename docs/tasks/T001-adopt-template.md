# T001 Adopt auto-template: docs, scripts, Makefile, settings

Milestone: M0
Feature: none (scaffold)

## AC

- `docs/` per `~/workspaces/auto-template`: FEATURES (from old CLAUDE.md + CONTEXT.md), ARCHITECTURE + one file per source domain, TASKS, memory
- `scripts/` copied from the template; `make check`, `make hooks`, `make docs-lint`, `make feature-gaps` added, existing INSTALL / RELEASE sections kept
- `.claude/settings.json` with memory dir `docs/memory`, allow / deny list
- `CLAUDE.md` rewritten on the template, `CONTEXT.md` folded into docs and removed

## Verify

- `make check` green, `make feature-gaps` lists nothing

## Notes

- Existing repo, not greenfield: Bootstrap step 2 (stack choice) skipped, stack is fixed (see `docs/memory/stack-choice.md`)

## Commits
