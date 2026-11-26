#!/usr/bin/env bash
# Render production UI fixtures, in isolated native Godot sessions.
# Preserve every case result even when one screen fails.
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
# Compile the shared fixture once before starting any rendered case.
ENGINE="$ROOT/.cache/bin/godot-$VERSION"
PREFLIGHT="$OUT/preflight.log"
if ! timeout 30s "$ENGINE" --headless --path "$ROOT" --check-only --script res://tests/qualification/cozy_ui_boot.gd > "$PREFLIGHT" 2>&1; then
 cat "$PREFLIGHT"
 exit 1
fi
if rg -q 'SCRIPT ERROR:|Parse Error:|Compile Error:' "$PREFLIGHT"; then
 cat "$PREFLIGHT"
 exit 1
fi
MANIFEST="$OUT/matrix.tsv"
printf 'viewport\tlocale\tarea\tresult\texit_code\n' > "$MANIFEST"
primary=(title hud inventory shop recipe notes dialogue build)
secondary=(recipe_v2 people history accounts receipts visitor payment supplier district sleep journey menu)
failed=0
capture_case() {
 local area="$1" lang="$2" width="$3" height="$4"
 local dir="$OUT/${width}x${height}"
 mkdir -p "$dir"
 local log="$dir/$area-$lang.log" shot="$dir/$area-$lang.png" status=0 result=pass
 rm -f "$shot"
 timeout 25s xvfb-run -a -s "-screen 0 ${width}x${height}x24" "$ROOT/.cache/bin/godot-$VERSION" --path "$ROOT" --rendering-method gl_compatibility --audio-driver Dummy res://tests/qualification/cozy_ui_boot.tscn -- --area "$area" --lang "$lang" --width "$width" --height "$height" --capture-dir "$dir" > "$log" 2>&1 || status=$?
 if rg -q 'SCRIPT ERROR:|Parse Error:|Compile Error:|Cozy UI preview rejected' "$log"; then
  result=script_or_layout_error
 elif [[ "$status" != 0 ]]; then
  result=engine_exit
 elif ! grep -q 'COZY_UI_STATUS .*"ready":true' "$log" || [[ ! -s "$shot" ]]; then
  result=missing_capture
 else
  # A screenshot of the wrong size cannot qualify a responsive case.
  if ! python3 - "$shot" "$width" "$height" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as f:
    header = f.read(24)
assert header[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", header[16:24]) == (int(sys.argv[2]), int(sys.argv[3]))
PY
  then result=wrong_size; fi
 fi
 printf '%sx%s\t%s\t%s\t%s\t%s\n' "$width" "$height" "$lang" "$area" "$result" "$status" >> "$MANIFEST"
 echo "COZY_REVIEW $width x $height $area $lang: $result"
 if [[ "$result" != pass ]]; then
  cat "$log"
  failed=$((failed+1))
  # Shared compilation failures invalidate the matrix, not just one fixture.
  if rg -q 'Parse Error:|Compile Error:' "$log"; then
   echo "Shared fixture compilation failed; aborting invalid matrix" >&2
   exit 1
  fi
 fi
}
for lang in ar_EG en; do
 for area in "${primary[@]}" "${secondary[@]}"; do
  capture_case "$area" "$lang" 1280 720
 done
 for area in "${primary[@]}"; do
  capture_case "$area" "$lang" 640 540
 done
done
echo "COZY_REVIEW_MATRIX_FAILED=$failed"
test "$failed" -eq 0
