#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

build_default_artifacts
log "Build complete: $DEFAULT_BINARY and $DIST_APP_BUNDLE"
