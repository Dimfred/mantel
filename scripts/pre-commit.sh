#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
mkdir -p tmp
log=tmp/pre-commit.log

diff_hash() {
  git diff | git hash-object --stdin
}

before="$(diff_hash)"
if ! timeout 600 make check >"$log" 2>&1; then
  tail -30 "$log" >&2
  echo "pre-commit: make check failed, full log: $log" >&2
  exit 1
fi

# `make lint` formats in place; the staged snapshot would miss those fixes.
if [[ "$(diff_hash)" != "$before" ]]; then
  git diff --name-only >&2
  echo "pre-commit: make lint reformatted files, review + git add them, commit again" >&2
  exit 1
fi
