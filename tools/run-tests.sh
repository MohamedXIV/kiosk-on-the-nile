#!/usr/bin/env bash
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/.cache/test-logs"
LOG=$(mktemp "$ROOT/.cache/test-logs/run-XXXXXX.log")
status=0
bash "$ROOT/tools/godot.sh" --headless --path "$ROOT" --script res://tests/run.gd -- --suite "${1:-all}" > "$LOG" 2>&1 || status=$?
cat "$LOG"
if rg -q 'SCRIPT ERROR:|^ERROR:|instances were leaked' "$LOG"; then status=1; fi
exit "$status"
