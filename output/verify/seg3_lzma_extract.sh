#!/bin/bash
# Segment 3: LZMA entries decompress byte-identically to the reference.
cd "$(dirname "$0")/../.." || exit 1

echo "=========================================================="
echo " Segment 3/6: LZMA extraction matches the reference (zipfile)"
echo "=========================================================="
sleep 1

echo "+ ./miniz_tester r output/verify/good   (all reader paths: heap/callback/iter)"
./miniz_tester r output/verify/good 2>&1 | grep -E "Testing archive|Total"

echo
echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"LZMA entries decompress correctly through all reader paths\""
bin/catch_tests "Zip reader LZMA tests" -c "LZMA entries decompress correctly through all reader paths" 2>&1 | tail -2

echo
echo "+ bin/catch_tests \"Zip reader LZMA tests\" -c \"LZMA entries extract correctly from file archives\""
bin/catch_tests "Zip reader LZMA tests" -c "LZMA entries extract correctly from file archives" 2>&1 | tail -2

echo
echo "+ reference side: python zipfile re-extracts test.bin, compare with the payload miniz was checked against"
python3 - <<'EOF'
import hashlib, zipfile
ref = open("output/assets/content.bin", "rb").read()
with zipfile.ZipFile("output/assets/lzma.zip") as z:
    out = z.read("test.bin")
print("  reference payload sha256:", hashlib.sha256(ref).hexdigest()[:32])
print("  zipfile extract  sha256:", hashlib.sha256(out).hexdigest()[:32])
print("  reference extract == payload:", out == ref)
print("  (miniz output was memcmp-verified against the same payload by catch_tests)")
EOF

sleep 1
