#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
mkdir -p "$PROJECT_ROOT/dist"

# compile any native Objective-C modules (pinch-zoom bridge, etc.)
source ./scripts/common.sh
compile_native_modules
# ensure the object file is available in cwd for {$LINK fp_magnify.o}
# common.sh writes into lib/<arch>-darwin; copy with wildcard
cp -f "$PROJECT_ROOT/lib/"*"-darwin"/fp_magnify.o . || true

echo "CI: compiling CLI binary..."
fpc -MObjFPC -Scghi -O1 -gw -Fu./src/core -FU./lib/aarch64-darwin -FE. -oflatpaint_cli src/cli/flatpaint_cli.lpr
cp -f flatpaint_cli dist/flatpaint_cli

echo "CI: compiling test runner..."
# add Lazarus/LCL unit paths so Forms/Controls are available
# allow LAZARUS_DIR to be overridden in the environment; otherwise resolve
# lazarus checkout relative to the workspace root (two levels up from project)
WORKSPACE_LAZARUS="$(cd "$PROJECT_ROOT/../.." 2>/dev/null && pwd)/lazarus"
LAZARUS_DIR="${LAZARUS_DIR:-$WORKSPACE_LAZARUS}"
# add path to compiled .o files for the current architecture so the
# LCL widgetset registration symbols are pulled in during linking
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  ARCH="aarch64"
fi
OBJDIR="${LAZARUS_DIR}/lcl/units/${ARCH}-darwin"
WIDGETDIR="${OBJDIR}/cocoa"  # include Cocoa widgetset objects as well

FPC_OPTS=( -dTESTING -Fl"$OBJDIR" -Fl"$WIDGETDIR" -k-framework -kUserNotifications -k-undefined -kdynamic_lookup \
          -Fu./src/core -Fu./src/app -Fu./src/tests -Fi"${LAZARUS_DIR}/lcl/include" \
          -Fu"${LAZARUS_DIR}/lcl" \
          -Fu"${LAZARUS_DIR}/lcl/widgetset" \
          -Fu"${LAZARUS_DIR}/lcl/nonwin32" \
          -Fu"${LAZARUS_DIR}/lcl/interfaces/cocoa" \
          -Fu"${LAZARUS_DIR}/components/lazutils" \
          -FE./dist )

# If DEBUG_TESTS=1, build tests with debug symbols and no optimizations
if [[ "${DEBUG_TESTS:-0}" == "1" ]]; then
  echo "CI: building tests with debug symbols (DEBUG_TESTS=1)"
  FPC_OPTS+=( -gl -O- )
fi
fpc "${FPC_OPTS[@]}" ./src/tests/flatpaint_tests.lpr
echo "CI: running tests..."
# Prefer plain executable, but fall back to app bundle binary if fpc produced a macOS .app
if [[ -x ./dist/flatpaint_tests ]]; then
  ./dist/flatpaint_tests
elif [[ -x ./dist/FlatPaint.app/Contents/MacOS/FlatPaint ]]; then
  ./dist/FlatPaint.app/Contents/MacOS/FlatPaint
else
  echo "CI: ERROR: test executable not found in ./dist (checked plain binary and .app bundle)" >&2
  ls -la ./dist || true
  exit 2
fi
echo "CI: tests finished"
