#!/bin/bash
# Segment 5: unsupported subtypes/methods give distinguishable error codes.
cd "$(dirname "$0")/../.." || exit 1

echo "=============================================================="
echo " Segment 5/6: Distinguishable error codes for unsupported input"
echo "=============================================================="
sleep 1

echo "LZMA entry, unsupported properties subtype -> MZ_ZIP_UNSUPPORTED_FEATURE"
echo "bzip2 (method 12) entry                  -> MZ_ZIP_UNSUPPORTED_METHOD"
echo

echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"Unsupported LZMA properties subtype gives a distinct error\" -s"
bin/catch_tests "Zip reader LZMA tests" -c "Unsupported LZMA properties subtype gives a distinct error" -s 2>&1 | grep -E "MZ_ZIP|passed|failed" | head -8

echo
echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"Unsupported compression method gives a distinct error\" -s"
bin/catch_tests "Zip reader LZMA tests" -c "Unsupported compression method gives a distinct error" -s 2>&1 | grep -E "MZ_ZIP|passed|failed" | head -10

echo
echo "+ ./miniz_tester r output/verify/bad  (error strings, per archive)"
./miniz_tester r output/verify/bad 2>&1 | grep "Error: Failed extracting"

sleep 1
