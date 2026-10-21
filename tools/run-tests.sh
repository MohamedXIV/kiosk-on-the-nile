#!/usr/bin/env bash
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/.cache/test-logs"
LOG=$(mktemp "$ROOT/.cache/test-logs/run-XXXXXX.log")
status=0
bash "$ROOT/tools/godot.sh" --headless --path "$ROOT" --script res://tests/run.gd -- --suite "${1:-all}" > "$LOG" 2>&1 || status=$?
printf "godot_exit=%s\n" "$status" > "$LOG.result"
cat "$LOG"
if rg -q 'SCRIPT ERROR:|^ERROR:|instances were leaked' "$LOG"; then status=1; printf "engine_diagnostic_error\n" >> "$LOG.result"; fi
exit "$status"
