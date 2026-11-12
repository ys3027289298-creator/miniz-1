#!/bin/bash
# Common helpers for the ZIP64 demo/verification segments.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
OUT_DIR="$REPO_ROOT/output"
DEMO=/tmp/mzdemo
BIN="$DEMO/bin"
SRC="$REPO_ROOT/miniz.c $REPO_ROOT/miniz_zip.c $REPO_ROOT/miniz_tdef.c $REPO_ROOT/miniz_tinfl.c"

mkdir -p "$DEMO" "$BIN"

title() {
    echo
    echo "================================================================"
    echo "  $1"
    echo "================================================================"
    echo
    sleep 2
}

pause() {
    echo
    echo "--- segment pause ---"
    sleep 3
}

build_demo() { # build_demo <output> <source.c> [extra include dir]
    local out=$1 src=$2 inc=${3:-$REPO_ROOT}
    gcc -O2 -I"$inc" "$src" $SRC -o "$out" -lm
}
