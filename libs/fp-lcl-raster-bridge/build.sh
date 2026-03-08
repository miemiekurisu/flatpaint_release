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

mkdir -p "$SCRIPT_DIR/dist"

fpc \
  -MObjFPC -Scghi -O2 \
  -dLCL -dLCLcocoa -dCOCOA \
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

echo "Built: $SCRIPT_DIR/dist/smoke_test"
