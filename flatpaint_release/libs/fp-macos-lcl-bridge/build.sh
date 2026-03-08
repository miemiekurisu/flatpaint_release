#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

detect_lazarus_dir() {
  local candidate
  if [[ -n "${LAZARUS_DIR:-}" ]]; then
    if [[ -d "$LAZARUS_DIR/lcl" && -d "$LAZARUS_DIR/components/lazutils" ]]; then
      printf '%s\n' "$LAZARUS_DIR"
      return 0
    fi
    printf 'LAZARUS_DIR is set but invalid: %s\n' "$LAZARUS_DIR" >&2
    exit 1
  fi

  for candidate in \
    "$SCRIPT_DIR/../../../lazarus" \
    "$SCRIPT_DIR/../../../../lazarus" \
    "$SCRIPT_DIR/../../../../../lazarus" \
    "/Applications/Lazarus" \
    "/usr/local/share/lazarus" \
    "/opt/homebrew/share/lazarus"
  do
    if [[ -d "$candidate/lcl" && -d "$candidate/components/lazutils" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'Unable to find Lazarus source tree. Set LAZARUS_DIR=/absolute/path/to/lazarus and retry.\n' >&2
  exit 1
}

LAZARUS_DIR="$(detect_lazarus_dir)"
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  FPC_ARCH="aarch64"
else
  FPC_ARCH="$ARCH"
fi

OBJ_DIR="$SCRIPT_DIR/lib/$FPC_ARCH-darwin"
mkdir -p "$OBJ_DIR" "$SCRIPT_DIR/dist"

LINK_OBJS=(fp_alpha.o fp_appearance.o fp_cgrender.o fp_listbg.o fp_magnify.o fp_scrollview.o)

cleanup_links() {
  local obj
  for obj in "${LINK_OBJS[@]}"; do
    rm -f "$SCRIPT_DIR/$obj"
  done
}
trap cleanup_links EXIT

clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -o "$OBJ_DIR/fp_alpha.o" "$SCRIPT_DIR/native/fp_alpha.m"
clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -o "$OBJ_DIR/fp_appearance.o" "$SCRIPT_DIR/native/fp_appearance.m"
clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -framework CoreGraphics -o "$OBJ_DIR/fp_cgrender.o" "$SCRIPT_DIR/native/fp_cgrender.m"
clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -o "$OBJ_DIR/fp_listbg.o" "$SCRIPT_DIR/native/fp_listbg.m"
clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -o "$OBJ_DIR/fp_magnify.o" "$SCRIPT_DIR/native/fp_magnify.m"
clang -c -O2 -arch "$ARCH" -mmacosx-version-min=11.0 -fobjc-arc -framework Cocoa -o "$OBJ_DIR/fp_scrollview.o" "$SCRIPT_DIR/native/fp_scrollview.m"

for obj in "${LINK_OBJS[@]}"; do
  ln -sf "$OBJ_DIR/$obj" "$SCRIPT_DIR/$obj"
done

pushd "$SCRIPT_DIR" >/dev/null
fpc \
  -MObjFPC -Scghi -O2 \
  -k-weak_framework -kAppKit \
  -k-weak_framework -kUserNotifications \
  -k-ld_classic \
  -dLCL -dLCLcocoa -dCOCOA \
  -Fi"$OBJ_DIR" \
  -Fi"$LAZARUS_DIR/lcl/include" \
  -Fi"$LAZARUS_DIR/lcl/interfaces/cocoa" \
  -Fu"$SCRIPT_DIR/src" \
  -Fu"$LAZARUS_DIR/lcl" \
  -Fu"$LAZARUS_DIR/lcl/widgetset" \
  -Fu"$LAZARUS_DIR/lcl/nonwin32" \
  -Fu"$LAZARUS_DIR/lcl/interfaces/cocoa" \
  -Fu"$LAZARUS_DIR/components/lazutils" \
  -Fu"$LAZARUS_DIR/lcl/units/$FPC_ARCH-darwin" \
  -Fu"$LAZARUS_DIR/lcl/units/$FPC_ARCH-darwin/cocoa" \
  -Fu"$LAZARUS_DIR/components/lazutils/lib/$FPC_ARCH-darwin" \
  -FU"$SCRIPT_DIR/dist" \
  -FE"$SCRIPT_DIR/dist" \
  "$SCRIPT_DIR/examples/smoke_test.lpr"
popd >/dev/null

echo "Built: $SCRIPT_DIR/dist/smoke_test"
