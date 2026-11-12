#!/bin/bash
# Segment 7: exceeding the extended (ZIP64) limits returns proper error codes.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 7/7: beyond the extended limits - proper error codes"

build_demo "$BIN/demo_overlimit" "$OUT_DIR/scripts/src/demo_overlimit.c"

echo "* hand-crafted ZIP64 end-of-central-directory records past miniz's practical limits"
"$BIN/demo_overlimit"

pause
