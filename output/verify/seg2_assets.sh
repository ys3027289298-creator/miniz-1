#!/bin/bash
# Segment 2: create the small test assets.
cd "$(dirname "$0")/../.." || exit 1

echo "=================================================="
echo " Segment 2/6: Create small LZMA/deflate test assets"
echo "=================================================="
sleep 1

echo "+ python3 output/tools/make_assets.py"
python3 output/tools/make_assets.py

mkdir -p output/verify/good output/verify/bad
cp output/assets/lzma.zip output/assets/deflate.zip output/verify/good/
cp output/assets/lzma_badcrc.zip output/assets/lzma_corrupt.zip output/assets/lzma_badprops.zip output/assets/bzip2.zip output/verify/bad/

echo "+ ls -l output/assets"
ls -l output/assets

echo "+ compression method of test.bin inside lzma.zip:"
python3 - <<'EOF'
import zipfile
with zipfile.ZipFile("output/assets/lzma.zip") as z:
    for i in z.infolist():
        print("  %-10s method=%-2d csize=%-4d usize=%d" % (i.filename, i.compress_type, i.compress_size, i.file_size))
EOF

sleep 1
