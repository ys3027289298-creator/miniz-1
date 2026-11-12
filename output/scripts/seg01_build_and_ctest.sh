#!/bin/bash
# Segment 1: build the library and run the repository's own test suite.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 1/7: build miniz and run the repo's own tests (cmake + ctest)"

cd "$REPO_ROOT"
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON
cmake --build build -j"$(nproc)"
cd build
ctest --output-on-failure

pause
