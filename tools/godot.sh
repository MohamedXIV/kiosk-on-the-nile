#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export XDG_DATA_HOME="$ROOT/.cache/data"
export XDG_CONFIG_HOME="$ROOT/.cache/config"
export XDG_CACHE_HOME="$ROOT/.cache/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec "$ROOT/.cache/bin/godot-4.7.2" "$@"
