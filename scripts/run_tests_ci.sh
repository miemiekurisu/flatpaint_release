#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

echo "CI: compiling CLI binary..."
fpc -MObjFPC -Scghi -O1 -gw -Fu./src/core -FU./lib/aarch64-darwin -FE. -oflatpaint_cli src/cli/flatpaint_cli.lpr
cp -f flatpaint_cli dist/flatpaint_cli

echo "CI: compiling test runner..."
FPC_OPTS=( -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist )
fpc "${FPC_OPTS[@]}" ./src/tests/flatpaint_tests.lpr
echo "CI: running tests..."
./dist/flatpaint_tests
echo "CI: tests finished"
