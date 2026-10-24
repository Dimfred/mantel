#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

docs="${1:-docs}"
scripts="$(dirname "$0")"
index="$docs/TASKS.md"
archive="$docs/TASKS-done.md"
arch="$docs/ARCHITECTURE.md"
features="$docs/FEATURES.md"
status=0

fail() {
  echo "docs-lint: $*" >&2
  status=1
}

for f in "$index" "$archive" "$arch" "$features"; do
  if [[ ! -f "$f" ]]; then
    echo "docs-lint: $f missing" >&2
    exit 1
  fi
done

if ! awk -v docs="$docs" -f "$scripts/tasks-lint.awk" "$index" "$archive"; then
  status=1
fi

anchors="$(awk -f "$scripts/anchor.awk" -f "$scripts/feature-anchors.awk" "$features")"

for path in "$docs"/tasks/T[0-9]*.md; do
  rel="tasks/$(basename "$path")"
  if ! grep -qF "($rel)" "$index" "$archive"; then
    fail "$path not linked from $index or $archive"
  fi

  if ! feature_line="$(grep -m1 '^Feature: ' "$path")"; then
    fail "$path: no 'Feature:' line"
    continue
  fi
  if [[ "$feature_line" == "Feature: none"* ]]; then
    continue
  fi
  if ! links="$(grep -oE '\(\.\./FEATURES\.md#[^)]+\)' <<<"$feature_line")"; then
    fail "$path: 'Feature:' needs [..](../FEATURES.md#<anchor>) links or 'none (<why>)'"
    continue
  fi
  while IFS= read -r link; do
    anchor="${link#(../FEATURES.md#}"
    anchor="${anchor%)}"
    if ! grep -qxF "$anchor" <<<"$anchors"; then
      fail "$path: no heading for FEATURES.md#$anchor"
    fi
  done <<<"$links"
done

if arch_links="$(grep -oE '\(architecture/[a-z0-9_-]+\.md\)' "$arch")"; then
  while IFS= read -r link; do
    rel="${link#(}"
    rel="${rel%)}"
    if [[ ! -f "$docs/$rel" ]]; then
      fail "$arch: missing file $docs/$rel"
    fi
  done <<<"$arch_links"
fi

for path in "$docs"/architecture/*.md; do
  name="$(basename "$path")"
  if [[ "$name" == "TEMPLATE.md" ]]; then
    continue
  fi
  if ! grep -qF "(architecture/$name)" "$arch"; then
    fail "$path not linked from $arch"
  fi
done

exit "$status"
