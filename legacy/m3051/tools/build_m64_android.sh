#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-godot}"
OUT="${1:-builds/android/AbyssalDominion_M64_Test.apk}"
mkdir -p "$(dirname "$OUT")"
"$GODOT_BIN" --headless --path "$(cd "$(dirname "$0")/.." && pwd)" --export-debug "Android" "$OUT"
echo "APK_READY=$OUT"
