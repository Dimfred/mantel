# Mantel

macOS daemon that draws images in native borderless windows over a terminal, driven by JSON commands on a FIFO; goals: correct placement / z-order, never crash, simple shell clients.

## Stack

- Swift 6 (tools 6.3, Swift 6 language mode), SPM, macOS 13+, AppKit / CoreGraphics / ApplicationServices, `os.Logger`
- Lint / format: `swift format` (toolchain, `.swift-format`), typecheck with `-warnings-as-errors`; tests: Swift Testing
- Reference projects (read only): none
- New dependency → propose (why, alternatives), add to `Blocked` in `docs/TASKS.md` + one line in `docs/HUMAN_TODO.md`, continue with other tasks. Exceptions (allowed without asking): none, Apple frameworks only
- Deps only via the package manager CLI (`swift package add-dependency`), never edit manifest / lock files by hand

## Layout

`Sources/mantel/<Domain>/` (library `MantelCore`): `Command`, `Server`, `Window`, `Terminal`, `Observer`, `Shared`.
`Sources/mantel-bin/` (executable `mantel`) stays thin: app setup + wiring only.
`Tests/MantelCoreTests/` mirrors `Sources/mantel/`, helpers / fakes in `Tests/MantelCoreTests/Helpers/`.
Details: `docs/ARCHITECTURE.md` + `docs/architecture/<domain>.md` (one per source domain, lowercase name), feature list: `docs/FEATURES.md`.

## Rules

- **Never modify files outside this repo** (reference projects are read only). Something needs a change there → add it to `Blocked` with the exact change, continue
- Scratch files (logs, probes, exports) go to `tmp/` in this repo (gitignored), never `/tmp` or the session scratchpad
- Small files (aim < 200 lines), one main type per file, early returns, no deep nesting
- No comments unless they explain a non-obvious why
- Explicit types; errors typed / wrapped with context, never swallowed (no `try?` that drops an error silently)
- Logging via `logger` (`Shared/Constants.swift`), never `print`
- Tests never next to sources, always in `Tests/`; real assertions, not just imports
- Linter / formatter configured to apply only non-breaking fixes; fix the rest by hand
- AppKit / window state only on `@MainActor`; callbacks from other threads are `@Sendable` and hop to main
- System access (NSWindow, CGWindowList, NSScreen, AX, NSWorkspace, file loads) goes through `WindowEnvironment` / injectable closures so logic stays unit-testable; tests never create real windows
- Pure logic (math, parsing, process walks) as `static` funcs on small enums / structs with plain inputs
- No force unwrap / force try / IUO (lint enforces)
- Never run `make install`, `make uninstall`, `make release*` (sudo, push, publishing): user only

## Commands

Always via make, never raw CLI:

- `make check`: lint, docs-lint, test. Must be green before every commit
- `make hooks`: installs the pre-commit hook (`scripts/pre-commit.sh` → `make check`, log in `tmp/pre-commit.log`; fails if `make lint` reformatted files → re-stage). Never `--no-verify`
- `make lint`: one target, `swift format` in place + strict lint + `swift build --build-tests -warnings-as-errors`, fails on what's left
- `make docs-lint`: checks the `docs/TASKS.md` format (the user's nvim plugin parses it) + task / feature / architecture links, part of `make check`
- `make feature-gaps`: `docs/FEATURES.md` sections no task links to
- `make test ARGS=<pattern>` (`swift test --filter`), `make dev` (`swift run`)
- Run with a timeout + log file, never pipe make into `tail`: `timeout 300 make check > tmp/check.log 2>&1; echo "exit=$?"; tail -30 tmp/check.log`
- Git: `git --no-pager ...`
- Logs of the running daemon: `log stream --predicate 'subsystem == "com.dimfred.mantel"' --level debug`

## Context hygiene

- Docs are the source of truth, not the conversation: `docs/TASKS.md` (task index + status, format in its header), `docs/tasks/` (one file per task with details), `docs/ARCHITECTURE.md` (overview + domain index), `docs/architecture/<domain>.md` (domain details), `docs/FEATURES.md` (what the app is, current target state), `docs/memory/` (decisions, user prefs, `MEMORY.md` index), `docs/HUMAN_TODO.md` (items for the user), `docs/CHECKLIST.md` (manual checks)
- Auto-compact at 200k (`.claude/settings.json`). Don't compact earlier. Keep docs up to date after every task so compaction loses nothing
- Read only the domains a task touches (code + `docs/architecture/<domain>.md`)
- Behavior change requested → update `docs/FEATURES.md` first, then plan tasks for it
- Finished milestones move from `docs/TASKS.md` to `docs/TASKS-done.md`; don't read the archive unless asked
- Decisions taken without the user → `docs/memory/decisions.md` so the user can revisit them

## Compact instructions

Keep the summary short (aim < 1.5k tokens). Rules already live in CLAUDE.md and `docs/memory/`, don't repeat them. Keep only:

- Current task id + what is done / left (files touched, design decisions not yet in docs)
- Open questions waiting on the user, verbatim
- User messages from this session not yet captured in docs or memory

## /loop protocol

Runs from a 2 minute cron: `/loop 2m work the next task per CLAUDE.md loop protocol`.
If the previous iteration is still mid-task, continue that task instead of starting a new one.

Each iteration:

1. Pick the first `[ ]` task in `docs/TASKS.md` (first milestone that has one)
2. Read its task file (if linked) + `docs/ARCHITECTURE.md` + `docs/architecture/<domain>.md` of touched domains + relevant `docs/memory/` entries + the linked `docs/FEATURES.md` section; read only touched domains
3. Implement with tests in the mirrored `Tests/MantelCoreTests/` dir
4. `make check` must be green
5. Needs visual / manual verification → mark `[?]`, add the checks to `docs/CHECKLIST.md`, move on
6. Update the checkbox in `docs/TASKS.md` (`[x]`), the task file (notes, follow-ups, commit shas), `docs/architecture/<domain>.md` if the design changed (`docs/ARCHITECTURE.md` only if domains or their connections changed), memory if a decision was made
7. Commit `<type>(<domain>): <what>` (`feat|fix|test|refactor|perf|docs|chore`), `make check` green first, one commit per useful unit, dependency changes in their own `chore(deps): ...` commit, no AI attribution, never push
8. Blocked (missing tool, new dependency, needs user decision) → add to `Blocked` with reason + one short line to `docs/HUMAN_TODO.md`, continue with the next independent task. Open choice that doesn't need the user → pick a sensible default, log it in `docs/memory/decisions.md`
9. Don't stop the loop (delete the cron) until the whole app is done (every `docs/FEATURES.md` item built or parked by the user). All tasks done or only blocked / `[?]` left → plan the next milestone yourself from `make feature-gaps` first, then polish, tests, perf, add it to `docs/TASKS.md`, note it in `docs/HUMAN_TODO.md` for review, start it
10. Milestone finished and committed → review: run `/code-review` (Skill tool) on the commits since `Last review` in `docs/TASKS.md`. Fix real findings with tests, `make check` green, commit `fix(<domain>): ...`. Findings needing a user decision → `Blocked`. Set `Last review: <sha>` to HEAD, then move the milestone block to the end of `docs/TASKS-done.md` (task files stay where they are)
11. Milestone finished, reviewed, committed, and context above ~150k → self-compact as the last action of the turn: `nvrr send '/compact<CR>continue<CR>'` (exact string, the only allowed `nvrr` call). Docs must already be up to date. Below that keep going and let auto-compact (200k) handle it
