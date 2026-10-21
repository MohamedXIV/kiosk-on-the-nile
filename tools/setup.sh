#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
python3 tools/install_dependencies.py
npm ci --ignore-scripts --no-audit --no-fund --cache "$ROOT/.cache/npm" --prefix tools
bash tools/compile-ink.sh
bash tools/godot.sh --headless --editor --path . --import
