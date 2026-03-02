#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

build_release_artifacts
log "Release build complete: $RELEASE_BINARY and $DIST_APP_BUNDLE"
