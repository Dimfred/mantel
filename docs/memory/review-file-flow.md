---
name: review-file-flow
description: User writes manual review notes to <PROJECT>_REVIEW.md at repo root; work them off, delete the file once fixed
metadata:
  type: feedback
---

User (bits, 2026-10-23): "from now on this is the flow i create <PROJECT>_REVIEW.md and we pick up things from there once fixed we delete it."

**Why:** the user's manual review findings live in a root file instead of chat.
**How to apply:** when such a file exists, turn its items into tasks / fixes. Never commit it (`*_REVIEW.md` is gitignored). Once every item is fixed and committed, delete the file (the user may delete it themselves). Related: [[decisions]].
