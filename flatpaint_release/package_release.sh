#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
APP_SRC="$ROOT_DIR/dist/FlatPaint.app"
RELEASE_DIR="$SCRIPT_DIR/release"
PKG_DIR="$RELEASE_DIR/packages"

if [[ ! -d "$APP_SRC" ]]; then
  echo "Missing $APP_SRC. Run: bash ./scripts/build-release.sh" >&2
  exit 1
fi

mkdir -p "$PKG_DIR"
rm -rf "$RELEASE_DIR/FlatPaint.app"
cp -R "$APP_SRC" "$RELEASE_DIR/FlatPaint.app"

for libdir in "$SCRIPT_DIR"/libs/*; do
  [[ -d "$libdir" ]] || continue
  libname="$(basename "$libdir")"
  rm -f "$PKG_DIR/$libname.zip"
  (
    cd "$SCRIPT_DIR/libs"
    zip -r "$PKG_DIR/$libname.zip" "$libname" \
      -x "$libname/dist/*" \
      -x "$libname/lib/*" \
      -x "*.ppu" \
      -x "*.o" \
      -x "*.compiled" \
      -x "*.rsj" \
      >/dev/null
  )
done

rm -f "$PKG_DIR/FlatPaint-macos-arm64.zip"
(cd "$RELEASE_DIR" && zip -r "$PKG_DIR/FlatPaint-macos-arm64.zip" "FlatPaint.app" >/dev/null)

(
  cd "$PKG_DIR"
  shasum -a 256 *.zip > SHA256SUMS.txt
)

echo "Release package prepared in: $RELEASE_DIR"
