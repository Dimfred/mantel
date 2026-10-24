---
name: scratch-in-tmp
description: Scratch/throwaway files go in the repo's tmp/ (gitignored), never the session scratchpad or /tmp
metadata:
  type: feedback
---

Throwaway scripts, logs, probes, intermediate outputs go in `tmp/` of this repo (monorepo: `<app>/tmp/`), not the Claude session scratchpad under `/private/tmp/...` or `/tmp`.

**Why:** user rejected a scratchpad write in bits: "no scratchpad use req/tmp".
**How to apply:** create scratch files with Write under `tmp/<topic>/`; `tmp/` must stay in `.gitignore`.
