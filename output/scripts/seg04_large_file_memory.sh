#!/bin/bash
# Segment 4: a single 5GB file - write, read, extract, all with constant memory.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 4/7: single 5GB file - ZIP64 round-trip with constant memory"

echo "* test asset: one sparse 5GB file"
truncate -s 5G "$DEMO/lf.bin"
ls -lah "$DEMO/lf.bin"
echo

build_demo "$BIN/demo_bigfile" "$OUT_DIR/scripts/src/demo_bigfile.c"

echo "* write + read + extract (deflate), watching peak memory"
/usr/bin/time -v "$BIN/demo_bigfile" "$DEMO/big.zip" "$DEMO/lf.bin" "$DEMO/lf.out" 1 2>&1 \
    | grep -E "OK|FAILED|Maximum resident|Elapsed"
echo

echo "* compare extracted data with the original"
cmp "$DEMO/lf.bin" "$DEMO/lf.out" && echo "extracted file is identical to the original"
echo

echo "* peak memory stays in the low MB range although the file is 5GB"

pause
