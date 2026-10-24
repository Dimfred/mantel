---
name: command-timeouts
description: Run make commands with a timeout and log to a scratch file instead of piping
metadata:
  type: feedback
---

Run make / package manager commands with `timeout` and redirect output into a log file, then tail the file: `timeout 120 make check > tmp/check.log 2>&1; echo "exit=$?"; tail -30 tmp/check.log` (see [[scratch-in-tmp]]).
Git: `git --no-pager`.

**Why:** in neovibe piping make into `| tail` hung and the user had to interrupt.
**How to apply:** every make / git call in the loop. On a timeout investigate, don't retry blindly.
