#!/usr/bin/env bash
# Fails if test/CI scripts look like they plant under mktemp/\$TMP without
# mentioning eigs.json. Heuristic gate — not a full AST. Bought: eddy#18 +
# dynamics#39 (2026-09-09) after EigenScript #1106.
set -euo pipefail
ROOT="${1:-.}"
cd "$ROOT"
mapfile -t hits < <(git grep -nE 'mktemp|\$\{?TMPDIR|\$TMP/|/tmp/' -- '*.sh' 'tests' 'test' '.github' 2>/dev/null || true)
if [[ ${#hits[@]} -eq 0 ]]; then
  echo "OK: no TMP/mktemp hits in shell/test paths"
  exit 0
fi
bad=0
for line in "${hits[@]}"; do
  file="${line%%:*}"
  if ! grep -q 'eigs\.json' "$file" 2>/dev/null; then
    echo "FAIL: $file references TMP/mktemp but never mentions eigs.json"
    bad=1
  fi
done
if [[ $bad -eq 1 ]]; then
  echo "After EigenScript #1106, planted-fault / tmp trees need eigs.json (or run under project root)."
  exit 1
fi
echo "OK: TMP/mktemp scripts also mention eigs.json"
