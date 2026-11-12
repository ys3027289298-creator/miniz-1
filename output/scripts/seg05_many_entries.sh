#!/bin/bash
# Segment 5: many entries - 65535 stays classic, 65536+ switches to ZIP64.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 5/7: many entries - 65535 (classic) vs 65536/70000/80000 (ZIP64)"

build_demo "$BIN/demo_many" "$OUT_DIR/scripts/src/demo_many.c"
build_demo "$BIN/demo_copy" "$OUT_DIR/scripts/src/demo_copy.c"

echo "* boundary: exactly 65535 entries stays classic zip"
"$BIN/demo_many" "$DEMO/many65535.zip" 65535
echo

echo "* boundary: 65536 entries automatically switches to zip64"
"$BIN/demo_many" "$DEMO/many65536.zip" 65536
echo

echo "* 70000 entries, verified by python's zipfile"
"$BIN/demo_many" "$DEMO/many70000.zip" 70000
python3 - "$DEMO/many70000.zip" <<'EOF'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
n = len(z.namelist())
print(f"  python zipfile: {n} entries")
assert n == 70000
print("  python zipfile: OK")
EOF
echo

echo "* 80000 entries via mz_zip_writer_add_from_zip_reader (two classic 40000-entry sources)"
python3 - "$DEMO" <<'EOF'
import sys, zipfile, os
for name in ("src1.zip", "src2.zip"):
    with zipfile.ZipFile(os.path.join(sys.argv[1], name), "w", compression=zipfile.ZIP_STORED) as z:
        for i in range(40000):
            z.writestr(f"f{i:05d}.txt", "x")
print("  two classic 40000-entry source zips created by python")
EOF
"$BIN/demo_copy" "$DEMO/copy80000.zip" "$DEMO/src1.zip" "$DEMO/src2.zip"
python3 - "$DEMO/copy80000.zip" <<'EOF'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
n = len(z.namelist())
print(f"  python zipfile: {n} entries")
assert n == 80000
print("  python zipfile: OK")
EOF

pause
