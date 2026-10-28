#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export XDG_DATA_HOME="$ROOT/.cache/data"
export XDG_CONFIG_HOME="$ROOT/.cache/config"
export XDG_CACHE_HOME="$ROOT/.cache/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
GODOT_VERSION=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["godot"]["version"])' "$ROOT/tools/dependencies.lock.json")
exec "$ROOT/.cache/bin/godot-$GODOT_VERSION" "$@"
