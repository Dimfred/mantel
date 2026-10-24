---
name: loop-never-stops
description: Never delete the loop cron; no tasks left → plan the next milestone yourself, user items go to docs/HUMAN_TODO.md
metadata:
  type: feedback
---

Never stop / delete the loop cron, also not after a milestone or when only blocked / `[?]` tasks remain.
Only stop once the whole app is done.
User (tcg-lightning-mobile, 2026-10-24): "don't stop the loop anymore", "you can stop the loop but only once we're done with the app".

**Why:** user wants continuous progress and reviews things later in batches.
**How to apply:** no `[ ]` task left → plan the next milestone from `docs/FEATURES.md` gaps, add it to `docs/TASKS.md`, start it.
Everything that needs the user (decisions, manual checks, new deps, changes outside the repo) → one very short line in `docs/HUMAN_TODO.md`, then continue.
Open choices that don't need the user → sensible default, logged in [[decisions]].
