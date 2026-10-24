# Tasks

Index of all open work, read top to bottom.
The checkbox is the only status; details live in `tasks/`.
Format is parsed by tooling and checked by `make docs-lint`:

- Sections: `## Blocked`, `## Later`, `## M<n> <title>` (milestones in execution order)
- Task line: `- [<s>] T<nnn> <title>` or `- [<s>] T<nnn> [<title>](tasks/T<nnn>-<slug>.md)`, only inside a milestone
- Status `<s>`: ` ` todo, `x` done, `?` done but needs a manual check (add it to `CHECKLIST.md`), `!` blocked (reason under `## Blocked`, mentioning the id)
- Ids: `T` + 3 or more digits, monotonic, never reused; next id = highest in `TASKS.md` + `TASKS-done.md` + 1
- Task file (`tasks/T<nnn>-<slug>.md`, copy `tasks/TEMPLATE.md`) once a task has AC / notes; one-liners need none. Never moved or renamed, holds no status. Its `Feature:` line links the `FEATURES.md` section(s) (`[..](../FEATURES.md#<anchor>)`, several allowed) or says `none (<why>)` (scaffold, refactor, review fixes, ...)
- Next task = first `[ ]` in the first milestone that has one
- Finished + reviewed milestone → whole block moves to the end of `TASKS-done.md` (incl. open `[?]`)

`make check` green is always implied.

Last review: none (`/code-review` after each milestone, see CLAUDE.md loop protocol)

## Blocked

## Later

Not now, don't pick up in the loop.

- Multi-window terminals (one process, many windows): image anchors to the frontmost window, may not be the one hosting the shell. User happy with current behavior (2026-10-24), keep as is; fix idea if it ever matters: client sends a window id
- Generic windows: `terminal_pid` → `window_pid` (any app window, not only terminals), cell grid optional (pixel coords)
- Configurable FIFO path (flag / env)

## M0 Bootstrap

- [x] T001 [Adopt auto-template: docs, scripts, Makefile, settings](tasks/T001-adopt-template.md)
- [x] T002 [Lint: swift format + warnings as errors](tasks/T002-lint.md)
- [x] T003 [Domain folders + WindowEnvironment test seams](tasks/T003-test-seams.md)
- [x] T004 [Unit tests for command, server, window, terminal](tasks/T004-unit-tests.md)
- [?] T005 [Visibility keeps z-order: show / toggle / hidden on move](tasks/T005-visibility-zorder.md)
- [x] T006 [Baseline: features built before bootstrap](tasks/T006-baseline.md)

## M1 Robustness

- [ ] T010 [FIFO: no lost back-to-back writes](tasks/T010-fifo-write-race.md)
- [ ] T011 [FIFO lifecycle: deleted FIFO, stop, isRunning race](tasks/T011-fifo-lifecycle.md)
- [ ] T012 [Terminal lookup: regular windows only](tasks/T012-terminal-layer-filter.md)
- [ ] T013 [Close removed windows without crash](tasks/T013-window-cleanup.md)
- [ ] T014 [Stop observers for terminals without images](tasks/T014-observer-cleanup.md)
- [x] T015 [SocketServer: wire or delete](tasks/T015-socket-server.md)
