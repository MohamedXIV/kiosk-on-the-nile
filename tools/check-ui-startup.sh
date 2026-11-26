#!/usr/bin/env bash
# Isolated native execution of the real source project. Never use a player's save.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p .cache/build-logs
LOG="$ROOT/.cache/build-logs/startup.log"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export XDG_DATA_HOME="$TMP/data"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
VERSION=$(python3 -c 'import json; print(json.load(open("tools/dependencies.lock.json"))["godot"]["version"])')
if ! timeout 60s "$ROOT/.cache/bin/godot-$VERSION" --headless --path "$ROOT" --script res://tests/qualification/main_startup_smoke.gd > "$LOG" 2>&1; then
 cat "$LOG"
 exit 1
fi
cat "$LOG"
if rg -n 'SCRIPT ERROR:|Parse Error:|Compile Error:|STARTUP_SMOKE_FAILED' "$LOG"; then
 exit 1
fi
if ! grep -qx 'STARTUP_SMOKE_PASS' "$LOG"; then
 echo 'Startup completion marker missing' >&2
 exit 1
fi
# Fail on engine errors before successful completion; preserve known teardown
# resource diagnostics in the log rather than claiming leak-free execution.
if sed '/^STARTUP_SMOKE_PASS$/q' "$LOG" | grep -E '^ERROR:'; then
 exit 1
fi
