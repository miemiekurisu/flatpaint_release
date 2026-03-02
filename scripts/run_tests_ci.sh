#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

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
LAZARUS_DIR="/Users/chrischan/Documents/workspace.nosync/lazarus"
# add path to compiled .o files for the current architecture so the
# LCL widgetset registration symbols are pulled in during linking
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  ARCH="aarch64"
fi
OBJDIR="${LAZARUS_DIR}/lcl/units/${ARCH}-darwin"
WIDGETDIR="${OBJDIR}/cocoa"  # include Cocoa widgetset objects as well

FPC_OPTS=( -dTESTING -Fl"$OBJDIR" -Fl"$WIDGETDIR" -k-framework -kUserNotifications \
          -Fu./src/core -Fu./src/app -Fu./src/tests -Fi"${LAZARUS_DIR}/lcl/include" \
          -Fu"${LAZARUS_DIR}/lcl" \
          -Fu"${LAZARUS_DIR}/lcl/widgetset" \
          -Fu"${LAZARUS_DIR}/lcl/nonwin32" \
          -Fu"${LAZARUS_DIR}/lcl/interfaces/cocoa" \
          -Fu"${LAZARUS_DIR}/components/lazutils" \
          -FE./dist )
fpc "${FPC_OPTS[@]}" ./src/tests/flatpaint_tests.lpr
echo "CI: running tests..."
./dist/flatpaint_tests
echo "CI: tests finished"
