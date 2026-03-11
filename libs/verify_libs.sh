#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

run_lib() {
  local lib="$1"
  echo "==> Building $lib"
  bash "$SCRIPT_DIR/$lib/build.sh"
}

run_lib "fp-raster-core"
run_lib "fp-viewport-kit"
run_lib "fp-lcl-raster-bridge"
run_lib "fp-lcl-clipboard-meta"
run_lib "fp-macos-lcl-bridge"

echo "==> All libraries built successfully"
