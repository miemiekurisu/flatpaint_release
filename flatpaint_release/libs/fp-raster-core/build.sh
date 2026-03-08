#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SCRIPT_DIR/dist"

fpc \
  -MObjFPC -Scghi -O2 \
  -Fu"$SCRIPT_DIR/src" \
  -FU"$SCRIPT_DIR/dist" \
  -FE"$SCRIPT_DIR/dist" \
  "$SCRIPT_DIR/examples/smoke_test.lpr"

echo "Built: $SCRIPT_DIR/dist/smoke_test"
