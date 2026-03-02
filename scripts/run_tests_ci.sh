#!/usr/bin/env bash
set -euo pipefail
echo "CI: compiling test runner..."
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
FPC_OPTS=( -Fu./src/core -Fu./src/app -Fu./src/tests -FE./dist )
fpc "${FPC_OPTS[@]}" ./src/tests/flatpaint_tests.lpr
echo "CI: running tests..."
./dist/flatpaint_tests
echo "CI: tests finished"
