#!/usr/bin/env bash
# Build + native startup smoke. Full gameplay acceptance is separate.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
mkdir -p .cache/build-logs
python3 tools/release.py check
python3 tools/release.py toolchain > .cache/build-logs/toolchain.json
bash tools/compile-ink.sh --check
python3 tools/extract-localization.py --check
if ! bash tools/godot.sh --headless --editor --path . --import > .cache/build-logs/import.log 2>&1; then
 cat .cache/build-logs/import.log
 exit 1
fi
if rg -n 'SCRIPT ERROR:|Parse Error:|Compile Error:' .cache/build-logs/import.log; then
 exit 1
fi
bash tools/check-ui-startup.sh
if ! bash tools/export-web.sh "$@" > .cache/build-logs/export.log 2>&1; then
 cat .cache/build-logs/export.log
 exit 1
fi
if rg -n 'SCRIPT ERROR:|Parse Error:|Compile Error:' .cache/build-logs/export.log; then
 exit 1
fi
echo 'Ink compilation, Godot import, native startup smoke and Web export completed. Logs: .cache/build-logs/'
