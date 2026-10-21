#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMPILER="$ROOT/.cache/inklecate/inklecate"
while IFS= read -r -d '' source; do
 if [[ ${1:-} == --check ]]; then
  temporary=$(mktemp)
  "$COMPILER" -o "$temporary" "$source"
  cmp "$temporary" "$source.json"
  rm "$temporary"
 else
  "$COMPILER" -o "$source.json" "$source"
 fi
done < <(find "$ROOT/content" "$ROOT/tests/fixtures" -name '*.ink' -print0)
