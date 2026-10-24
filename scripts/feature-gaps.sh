#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

docs="${1:-docs}"
scripts="$(dirname "$0")"
features="$docs/FEATURES.md"

if [[ ! -f "$features" ]]; then
  echo "feature-gaps: $features missing" >&2
  exit 1
fi

task_files=("$docs"/tasks/T[0-9]*.md)
linked=""
if (( ${#task_files[@]} > 0 )); then
  if lines="$(grep -h '^Feature: ' "${task_files[@]}")"; then
    if found="$(grep -oE 'FEATURES\.md#[^)]+' <<<"$lines")"; then
      linked="$(sed 's/^FEATURES\.md#//' <<<"$found")"
    fi
  fi
fi

echo "FEATURES.md sections no task links to (subsection link covers its parents):"
awk -f "$scripts/anchor.awk" -f "$scripts/feature-gaps.awk" <(printf '%s\n' "$linked") "$features"
