#!/bin/bash
# Record every demo segment with asciinema into output/recordings/ and keep a
# plain-text log of each segment in output/logs/. Non-interactive: each
# recording ends when the segment script exits (no keyboard input needed).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

segments=(
    seg01_build_and_ctest
    seg02_boundary_unit_tests
    seg03_before_after_4g
    seg04_large_file_memory
    seg05_many_entries
    seg06_interop
    seg07_overlimit_errors
)

for seg in "${segments[@]}"; do
    echo "=== recording $seg ==="
    asciinema rec --overwrite --title "$seg" \
        --command "bash 'scripts/$seg.sh' 2>&1 | tee 'logs/$seg.log'" \
        "recordings/$seg.cast"
done

echo "all segments recorded to output/recordings/"
