#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

python3 scripts/extract_lucide_icons.py --sync-only

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/flatpaint-lucide.XXXXXX")"
TMP_RENDERED="$TMP_DIR/rendered"
mkdir -p "$TMP_RENDERED"

for svg in assets/icons/lucide/*.svg; do
  base="$(basename "$svg")"
  qlmanage -t -s 256 -o "$TMP_DIR" "$svg"
  python3 scripts/extract_lucide_icons.py --normalize \
    "$TMP_DIR/$base.png" \
    "$TMP_RENDERED/$base.png"
done

mkdir -p assets/icons/rendered
cp "$TMP_RENDERED"/*.png assets/icons/rendered/

echo "Refreshed Lucide rendered assets in assets/icons/rendered"
