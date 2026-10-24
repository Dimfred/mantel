---
name: permission-model
description: How Claude edit/bash permissions work (global edit-guard hook + project allowlist)
metadata:
  type: reference
---

Edits gated by global PreToolUse hook `~/.config/adot/dotfiles/claude/hooks/edit-guard.sh`: Edit/Write inside dirs in `~/.config/adot/dotfiles/claude/trusted-edit-dirs` run without prompt; `.claude/`, `.git/`, `.mcp.json` still ask.
rm/rmdir/unlink/git rm/git clean always ask.
Project `.claude/settings.json` allows make, read-only git, git add/commit and the one `nvrr` compact command; denies git push, sudo, `security`, `secret-tool`.
Stack tools get added to the allow list at bootstrap.

**How to apply:** never widen these without the user asking; file changes only via Edit/Write, never Bash.
If the repo dir isn't in trusted-edit-dirs, ask the user to add it (don't edit it yourself).
