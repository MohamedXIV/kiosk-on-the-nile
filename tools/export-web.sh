#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=/tmp/kiosk-port-web
MODE=debug
while [[ $# -gt 0 ]]; do
 case "$1" in
  --out) OUT=$2; shift 2;;
  --release) MODE=release; shift;;
  *) echo "Unknown option: $1" >&2; exit 2;;
 esac
done
mkdir -p "$OUT"
bash "$ROOT/tools/godot.sh" --headless --path "$ROOT" --export-"$MODE" Web "$OUT/index.html"
cp -R "$ROOT/content" "$OUT/"
