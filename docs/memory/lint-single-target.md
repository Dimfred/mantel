---
name: lint-single-target
description: One `make lint` target that formats + applies safe fixes + lints; never unsafe autofixes
metadata:
  type: feedback
---

`make lint` does everything: format, apply non-breaking autofixes, lint, typecheck, fail on what's left.
No separate `format` / `lint-fix` targets unless the language really needs them.
Linter / formatter configured so autofixes never change behavior (e.g. never biome `--unsafe`); remaining issues fixed by hand.

**Why:** user (auto-template, 2026-10-24): "lint should just do lint-fix if the fix is non-breaking ... biome has an unsafe option things like this should not be happening".
**How to apply:** at bootstrap wire `lint` this way in the Makefile; `make check` = `lint` + `test`.
