# Human TODO

Short items for the user, each with an id (`H1`, `H2`, ...); details in `docs/TASKS.md` (Blocked) and `docs/CHECKLIST.md`.
Ask Claude about any item by its id.
Remove an item once settled.

- H1: `SocketServer` is compiled but never used → delete or wire as second transport? (T015)
- H2: terminal apps with several windows in one process: image anchors to the frontmost one; want a smarter pick (e.g. client sends window id)? (T016)
- H3: review bootstrap (docs, M0 diff, `docs/memory/decisions.md`), then commit `chore: bootstrap`, restart Claude (memory dir moves to `docs/memory`), start `/loop 2m work the next task per CLAUDE.md loop protocol`
- H4: manual checks for T005 in `docs/CHECKLIST.md`
