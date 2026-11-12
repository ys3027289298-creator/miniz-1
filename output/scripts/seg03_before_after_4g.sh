#!/bin/bash
# Segment 3: the >4GB finalize case - old code fails, fixed code switches to ZIP64.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 3/7: archive crossing 4GB - before (fails) vs after (auto ZIP64)"

ORIG=/tmp/miniz_orig
git -C "$REPO_ROOT" worktree remove --force "$ORIG" 2>/dev/null || true
git -C "$REPO_ROOT" worktree add "$ORIG" HEAD
printf '#ifndef MINIZ_EXPORT\n#define MINIZ_EXPORT\n#endif\n' > "$ORIG/miniz_export.h"

echo "* test assets: two sparse files, 2GB + 3GB (each < 4GB, sum > 4GB)"
truncate -s 2G "$DEMO/part1.bin"
truncate -s 3G "$DEMO/part2.bin"
ls -lah "$DEMO"/part*.bin
echo

echo "* BEFORE (pristine HEAD): finalize used to fail past 4GB"
gcc -O2 -I"$ORIG" "$OUT_DIR/scripts/src/demo_cross4g.c" \
    "$ORIG"/miniz.c "$ORIG"/miniz_zip.c "$ORIG"/miniz_tdef.c "$ORIG"/miniz_tinfl.c -o "$BIN/cross4g_before" -lm
set +e
"$BIN/cross4g_before" "$DEMO/cross_before.zip" "$DEMO/part1.bin" "$DEMO/part2.bin"
echo "exit code: $?"
set -e
echo

echo "* AFTER (with fix): finalize automatically switches to ZIP64"
build_demo "$BIN/cross4g_after" "$OUT_DIR/scripts/src/demo_cross4g.c"
/usr/bin/time -v "$BIN/cross4g_after" "$DEMO/cross_after.zip" "$DEMO/part1.bin" "$DEMO/part2.bin" 2>&1 | grep -E "OK|FAILED|Maximum resident"
echo

echo "* read the fixed archive back with miniz"
build_demo "$BIN/demo_check" "$OUT_DIR/scripts/src/demo_check.c"
"$BIN/demo_check" "$DEMO/cross_after.zip"
echo

echo "* read the same archive with python's zipfile (independent implementation)"
python3 - "$DEMO/cross_after.zip" <<'EOF'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for i in z.infolist():
    print(f"  {i.filename} size={i.file_size}")
assert [i.file_size for i in z.infolist()] == [2 << 30, 3 << 30]
print("  python zipfile: OK")
EOF

git -C "$REPO_ROOT" worktree remove --force "$ORIG"
pause
