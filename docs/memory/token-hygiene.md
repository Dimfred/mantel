---
name: token-hygiene
description: Auto-compact at 200k, no early self-compacts, state kept in docs so nothing is lost
metadata:
  type: feedback
---

Auto-compact at 200k (`autoCompactWindow` in committed `.claude/settings.json`).
A fresh session starts around 45k, so compacting after every task or milestone wastes the window.
Self-compact only after a reviewed milestone when context is above ~150k.
Persist all state in `docs/TASKS.md`, `docs/ARCHITECTURE.md` and `docs/memory/` after every task.

**Why:** user in neovibe: "compact less often, we start at 45k tokens anyways"; settled on 150k there, raised to 200k in tcg-lightning-mobile.
**How to apply:** don't stop the loop to compact. Self-compact is `nvrr send '/compact<CR>continue<CR>'` (Claude runs inside nvim; this exact command is allowlisted, nothing else of nvrr).
