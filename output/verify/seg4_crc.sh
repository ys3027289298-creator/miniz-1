#!/bin/bash
# Segment 4: checksum / corruption failures are detected.
cd "$(dirname "$0")/../.." || exit 1

echo "====================================================="
echo " Segment 4/6: Checksum failure detection (corrupt zips)"
echo "====================================================="
sleep 1

echo "+ ./miniz_tester r output/verify/bad   (every archive must fail)"
./miniz_tester r output/verify/bad 2>&1 | grep -E "Testing archive|Error|Total errors"

echo
echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"LZMA CRC-32 mismatch is detected\" -s"
bin/catch_tests "Zip reader LZMA tests" -c "LZMA CRC-32 mismatch is detected" 2>&1 | tail -2

echo
echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"Corrupted LZMA data is detected\""
bin/catch_tests "Zip reader LZMA tests" -c "Corrupted LZMA data is detected" 2>&1 | tail -2

sleep 1
