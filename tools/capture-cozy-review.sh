#!/usr/bin/env bash
# Render representative production UI fixtures in both locales using the pinned engine.
# This is a visual-review artifact, not a claim of acceptance or full interaction coverage.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
OUT="$ROOT/.cache/build-logs/cozy-review"
mkdir -p "$OUT"
command -v xvfb-run >/dev/null || { echo "xvfb-run missing" >&2; exit 1; }
VERSION=$(python3 -c 'import json; print(json.load(open("tools/dependencies.lock.json"))["godot"]["version"])')
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export XDG_DATA_HOME="$TMP/data"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
# Start with the primary visual surfaces; expand the matrix after reviewing them.
for lang in ar_EG en; do
 for area in title hud inventory shop recipe notes dialogue build; do
  log="$OUT/$area-$lang.log"
  shot="$OUT/$area-$lang.png"
  rm -f "$shot"
  if ! timeout 60s xvfb-run -a -s "-screen 0 1280x720x24" "$ROOT/.cache/bin/godot-$VERSION" --path "$ROOT" --rendering-method gl_compatibility --audio-driver Dummy res://tests/qualification/cozy_ui_boot.tscn -- --area "$area" --lang "$lang" --width 1280 --height 720 --capture-dir "$OUT" > "$log" 2>&1; then
   cat "$log"; exit 1
  fi
  if rg -n 'SCRIPT ERROR:|Parse Error:|Compile Error:|Cozy UI preview rejected' "$log"; then exit 1; fi
  if ! grep -q 'COZY_UI_STATUS .*"ready":true' "$log" || [[ ! -s "$shot" ]]; then
   cat "$log"; echo "Missing ready status or screenshot: $area $lang" >&2; exit 1
  fi
  echo "COZY_REVIEW_CAPTURED $area $lang"
 done
done
