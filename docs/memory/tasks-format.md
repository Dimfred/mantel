---
name: tasks-format
description: Docs split index + detail files; TASKS.md parsed by the user's nvim plugin (strict format, checkbox = only status); features = target state, tasks = work
metadata:
  type: feedback
---

`docs/TASKS.md` = index (milestones, one line per task, checkbox is the only status), details in `docs/tasks/T<nnn>-<slug>.md` (never moved, no status inside, `Feature:` link into `FEATURES.md`).
Format spec lives in the `TASKS.md` header; `make docs-lint` enforces it.
No `## TODO` / `## DONE` sections and no status folders; finished milestones move to the end of `TASKS-done.md`.
Files read top to bottom, no prepending.
Same index + detail split for architecture: `ARCHITECTURE.md` overview + `architecture/<domain>.md`.
`FEATURES.md` stays one file: current target state (what the app is), tasks = how we get there; written spec from the user becomes `FEATURES.md`.

**Why:** user (auto-template, 2026-10-24) builds a neovim plugin that parses the task files for an overview; status in two places would drift, moving files would break links. Big `ARCHITECTURE.md` (8–9k tokens in neovibe / bits) was read whole every loop iteration.
**How to apply:** never deviate from the line format; new task = next free id; create a task file only once there's more than a one-liner; behavior change → `FEATURES.md` first, then tasks.
