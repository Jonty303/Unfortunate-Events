#!/usr/bin/env bash
# Import, run touch and combat regressions, then export a single-threaded Web build.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_BIN:-$HOME/.local/bin/godot-4.5.2}"
[[ -x "$GODOT" ]] || { echo "Godot missing. Run: bash tools/install_godot.sh" >&2; exit 1; }
VERSION="$("$GODOT" --headless --version)"
[[ "$VERSION" == 4.5.2.stable* ]] || { echo "Expected Godot 4.5.2 with matching templates, got: $VERSION" >&2; exit 1; }
mkdir -p "$ROOT/build/web" "$ROOT/build/logs"
run_checked() {
  local name="$1"; shift
  "$GODOT" "$@" 2>&1 | tee "$ROOT/build/logs/$name.log"
  # Godot can report script failures while returning exit code 0.
  if grep -E '(^|[[:space:]])(SCRIPT ERROR:|ERROR:)|Parse Error|Failed to load script' "$ROOT/build/logs/$name.log" >/dev/null; then
    echo "Godot reported an error. See build/logs/$name.log" >&2
    exit 1
  fi
}
run_checked import --headless --editor --path "$ROOT" --import
run_checked touch-tests --headless --path "$ROOT" --script res://tests/touch_smoke.gd
if ! grep -F 'TOUCH TESTS PASSED' "$ROOT/build/logs/touch-tests.log" >/dev/null; then
  echo "The touch test suite did not reach its success marker." >&2; exit 1
fi
run_checked combat-tests --headless --path "$ROOT" --script res://tests/combat_smoke.gd
if ! grep -F 'COMBAT TESTS PASSED' "$ROOT/build/logs/combat-tests.log" >/dev/null; then
  echo "The combat test suite did not reach its success marker." >&2; exit 1
fi
run_checked export --headless --path "$ROOT" --export-release Web "$ROOT/build/web/index.html"
[[ -s "$ROOT/build/web/index.html" && -s "$ROOT/build/web/index.wasm" && -s "$ROOT/build/web/index.pck" ]] || {
  echo "Export did not create all required browser files." >&2; exit 1;
}
printf '\nWeb build: %s/build/web\nStart it: python3 tools/serve_web.py\n' "$ROOT"
