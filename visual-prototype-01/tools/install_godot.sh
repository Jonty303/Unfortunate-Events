#!/usr/bin/env bash
# Pinned, standard (non-.NET) Godot installation for this visual prototype.
# Does not replace an existing `godot` command. Downloads are SHA-256 checked.
set -euo pipefail
VERSION="4.5.2"
BASE="https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable"
[[ "$(uname -s)" == "Linux" ]] || { echo "This installer is for Linux/Codespaces." >&2; exit 1; }
case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64; EDITOR_SHA=87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03 ;;
  aarch64|arm64) ARCH=arm64; EDITOR_SHA=97ad6d1b74020bd591520e4f8810c6a07451af75eefa0932f57daeb805124618 ;;
  *) echo "Unsupported CPU architecture: $(uname -m)" >&2; exit 1 ;;
esac
for tool in curl unzip python3 sha256sum install; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. Run: sudo apt-get update && sudo apt-get install -y curl unzip python3 ca-certificates" >&2; exit 1; }
done
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/unfortunate-events/godot/$VERSION"
BIN="$HOME/.local/bin/godot-$VERSION"
TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$VERSION.stable"
mkdir -p "$CACHE" "$(dirname "$BIN")" "$TEMPLATES"
fetch_verified() {
  local filename="$1" expected="$2"
  if [[ -f "$CACHE/$filename" ]] && printf '%s  %s\n' "$expected" "$CACHE/$filename" | sha256sum --check --status; then
    echo "Using verified cached $filename"
    return
  fi
  curl --fail --location --retry 3 --output "$CACHE/$filename.part" "$BASE/$filename"
  printf '%s  %s\n' "$expected" "$CACHE/$filename.part" | sha256sum --check
  mv "$CACHE/$filename.part" "$CACHE/$filename"
}
EDITOR="Godot_v${VERSION}-stable_linux.${ARCH}.zip"
fetch_verified "$EDITOR" "$EDITOR_SHA"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q "$CACHE/$EDITOR" -d "$TMP"
install -m 0755 "$TMP/Godot_v${VERSION}-stable_linux.${ARCH}" "$BIN"

# Official all-platform template bundle is ~1.35 GB. Keep only Web templates installed.
# Cache avoids a second download on repeated runs.
BUNDLE="Godot_v${VERSION}-stable_export_templates.tpz"
fetch_verified "$BUNDLE" ea50e5183f057d42b22120d0d0340205b98f51f8ff13c33c70fd4ac9077d2019
python3 - "$CACHE/$BUNDLE" "$TEMPLATES" <<'PY'
from pathlib import Path
import shutil
import sys
import zipfile
archive, destination = sys.argv[1:]
destination = Path(destination)
with zipfile.ZipFile(archive) as z:
    names = [n for n in z.namelist() if n.startswith('templates/web_') and n.endswith('.zip')]
    if not names:
        raise SystemExit('No web templates found in the downloaded bundle.')
    for name in names:
        target = destination / Path(name).name
        with z.open(name) as src, target.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        print('Installed', target.name)
PY
"$BIN" --headless --version
printf '\nInstalled: %s\nWeb templates: %s\nNext: bash tools/export_web.sh\n' "$BIN" "$TEMPLATES"
