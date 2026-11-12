#!/bin/bash
# Segment 6: interoperability between miniz and an independent implementation
# (python's zipfile), in both the classic and the ZIP64 format, both directions.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 6/7: old/new format interop - miniz <-> python zipfile"

build_demo "$BIN/demo_many" "$OUT_DIR/scripts/src/demo_many.c"
build_demo "$BIN/demo_check" "$OUT_DIR/scripts/src/demo_check.c"

echo "* miniz writes a classic zip, python reads it"
"$BIN/demo_many" "$DEMO/miniz_classic.zip" 3
echo

echo "* python writes classic + forced-zip64 zips, miniz reads them"
python3 - "$DEMO" "$BIN/demo_check" <<'EOF'
import subprocess, sys, zipfile, zlib, os

demo, check = sys.argv[1], sys.argv[2]

# miniz classic zip -> python
z = zipfile.ZipFile(os.path.join(demo, "miniz_classic.zip"))
assert z.namelist() == ["file000000.txt", "file000001.txt", "file000002.txt"]
assert all(z.read(n) == b"x" for n in z.namelist())
print("  python read miniz classic zip: OK")

# python -> miniz, classic and forced zip64
payloads = {"hello.txt": b"hello zip world\n" * 100,
            "data.bin": bytes(range(256)) * 64}
for name, force in (("py_classic.zip", False), ("py_zip64.zip", True)):
    with zipfile.ZipFile(os.path.join(demo, name), "w", compression=zipfile.ZIP_DEFLATED) as z:
        for fn, data in payloads.items():
            zi = zipfile.ZipInfo(fn)
            with z.open(zi, "w", force_zip64=force) as f:
                f.write(data)
    out = subprocess.run([check, os.path.join(demo, name)],
                         capture_output=True, text=True, check=True).stdout
    print(f"  miniz read {name}: {out.splitlines()[0]}")
    for fn, data in payloads.items():
        want = f"{fn} size={len(data)} crc={zlib.crc32(data) & 0xFFFFFFFF:08x}"
        assert want in out, f"mismatch: {want!r} not in {out!r}"
    print(f"  miniz extracted CRCs match python's for {name}: OK")
EOF

echo "* python writes a true zip64 archive (66000 entries), miniz reads it"
python3 - "$DEMO/py_many64.zip" <<'EOF'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", compression=zipfile.ZIP_STORED) as z:
    for i in range(66000):
        z.writestr(f"f{i:05d}.txt", "x")
print("  python wrote 66000-entry zip64 archive")
EOF
"$BIN/demo_check" "$DEMO/py_many64.zip" | head -2

pause
