#!/bin/bash
# Records all verification segments with asciinema (titled, paused between
# segments, non-interactive). Artifacts land in output/recordings/.
cd "$(dirname "$0")/../.." || exit 1

mkdir -p output/recordings

run_seg() {
    local script="$1" title="$2" cast="$3"
    echo ">>> recording $cast : $title"
    asciinema rec --overwrite --headless --idle-time-limit 3 \
        --title "$title" \
        --command "bash output/verify/$script" \
        "output/recordings/$cast"
    echo ">>> done $cast, pausing between segments..."
    sleep 2
}

run_seg seg1_build.sh              "1/6 Build (repo entry points)"            seg1_build.cast
run_seg seg2_assets.sh             "2/6 Create small test assets"             seg2_assets.cast
run_seg seg3_lzma_extract.sh       "3/6 LZMA extraction matches reference"    seg3_lzma_extract.cast
run_seg seg4_crc.sh                "4/6 Checksum failure detection"           seg4_crc.cast
run_seg seg5_unsupported.sh        "5/6 Distinguishable unsupported errors"   seg5_unsupported.cast
run_seg seg6_deflate_regression.sh "6/6 Deflate path zero regression"         seg6_deflate_regression.cast

echo "all segments recorded:"
ls -l output/recordings/
