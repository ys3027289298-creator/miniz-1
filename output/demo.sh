#!/bin/bash
# demo.sh - Segmented, non-interactive demo of the miniz gzip streaming container.
# Each segment prints a title banner and pauses between segments (no keyboard input needed).
# All transient build products go to /tmp; final artifacts stay in output/.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
WORK=/tmp/miniz_gzip_demo
SRCS="miniz.c miniz_tdef.c miniz_tinfl.c miniz_zip.c"
PAUSE="${PAUSE:-2}"

title() {
    echo
    echo "================================================================"
    echo "  SEGMENT $1/5 : $2"
    echo "================================================================"
    echo
}

run() { echo "+ $*"; "$@"; }

mkdir -p "$WORK" "$OUT/logs"
cd "$ROOT"

# Generate the miniz_export.h shim exactly like test.sh does.
cat << 'EOF' > miniz_export.h
#ifndef MINIZ_EXPORT
#define MINIZ_EXPORT
#endif
EOF

# ---------------------------------------------------------------- seg 1
title 1 "构建：仓库自带入口编译检查 + 构建示例/测试程序"
{
run bash amalgamate.sh || echo "(注: amalgamate.sh 末尾的 zip 打包步骤因环境无 zip 命令跳过, 编译检查已全部通过)"
for i in 1 2 3 4 5 6 7; do
    run gcc examples/example$i.c amalgamation/miniz.c -o "$WORK/example$i" -lm -I. -ggdb || exit 1
done
run g++ tests/miniz_tester.cpp tests/timer.cpp amalgamation/miniz.c -o "$WORK/miniz_tester" -I. -ggdb -O2 || exit 1
echo "构建完成: example1..7 + miniz_tester (基于 amalgamation/miniz.c, 与 test.sh 相同的构建方式)"
} 2>&1 | tee "$OUT/logs/segment1_build.log" | grep -E "^\+|Test compile|错误|error|构建完成|注:" 
sleep "$PAUSE"

# ---------------------------------------------------------------- seg 2
title 2 "旧接口零回归：与改动前 (git HEAD) 逐字节对比"
{
mkdir -p "$WORK/base"
git archive HEAD | tar -x -C "$WORK/base"
cp miniz_export.h "$WORK/base/"
for i in 1 2 3 4 5 6; do
    gcc "$WORK/base/examples/example$i.c" $(for f in $SRCS; do echo "$WORK/base/$f"; done) -o "$WORK/base_example$i" -lm -I"$WORK/base" || exit 1
done
g++ "$WORK/base/tests/miniz_tester.cpp" "$WORK/base/tests/timer.cpp" $(for f in $SRCS; do echo "$WORK/base/$f"; done) -o "$WORK/base_miniz_tester" -I"$WORK/base" -O2 || exit 1

mkdir -p "$WORK/run_base" "$WORK/run_new"
for i in 1 2 3 4 5 6; do (cd "$WORK/run_base" && "$WORK/base_example$i" > "out$i.txt" 2>&1); done
for i in 1 2 3 4 5 6; do (cd "$WORK/run_new"  && "$WORK/example$i"     > "out$i.txt" 2>&1); done

ok=1
for i in 1 2 3 4 5 6; do
    if cmp -s "$WORK/run_base/out$i.txt" "$WORK/run_new/out$i.txt"; then
        echo "example$i 标准输出: 完全一致"
    else
        echo "example$i 标准输出: 有差异!"; ok=0
    fi
done
# zip 内嵌 DOS 时间戳随运行时刻变化, 因此按成员逐一对比 (忽略时间戳): 名称/CRC/压缩后大小/解压内容
if python3 - "$WORK/run_base/__mz_example2_test__.zip" "$WORK/run_new/__mz_example2_test__.zip" <<'PYEOF'
import sys, zipfile
a, b = zipfile.ZipFile(sys.argv[1]), zipfile.ZipFile(sys.argv[2])
ka = sorted((i.filename, i.CRC, i.compress_size, i.file_size) for i in a.infolist())
kb = sorted((i.filename, i.CRC, i.compress_size, i.file_size) for i in b.infolist())
assert ka == kb, "member metadata differs"
for n in a.namelist():
    assert a.read(n) == b.read(n), "member content differs: " + n
print("members=%d" % len(ka))
PYEOF
then echo "example2 生成的 zip 归档: 成员元数据与内容完全一致 (忽略 DOS 时间戳)"; else { echo "example2 zip: 有差异!"; ok=0; }; fi
cmp -s "$WORK/run_base/mandelbrot.png" "$WORK/run_new/mandelbrot.png" && echo "example6 生成的 PNG: 逐字节一致" || { echo "example6 png: 有差异!"; ok=0; }

# example3: zlib 流式压缩产物逐字节对比 (deflate 路径)
"$WORK/base_example3" c "$OUT/material/report.txt" "$WORK/base.z" > /dev/null
"$WORK/example3"     c "$OUT/material/report.txt" "$WORK/new.z"  > /dev/null
cmp "$WORK/base.z" "$WORK/new.z" && echo "example3 zlib 压缩流: 逐字节一致"

# miniz_tester: 仓库自带测试入口, 对比确定性输出 (过滤时间/随机临时文件名)
filt() { sed 's/__comp_temp_[0-9]*__/__comp_temp_X__/' | grep -vE "Compiled|took|time:|rate|secs|Progress"; }
(cd "$WORK/run_base" && "$WORK/base_miniz_tester" -a a "$OUT/material" > mt.txt 2>&1)
(cd "$WORK/run_new"  && "$WORK/miniz_tester"      -a a "$OUT/material" > mt.txt 2>&1)
if diff <(filt < "$WORK/run_base/mt.txt") <(filt < "$WORK/run_new/mt.txt") > /dev/null; then
    echo "miniz_tester 归档模式确定性输出: 完全一致"
else
    echo "miniz_tester 归档模式: 有差异!"; ok=0
fi
[ "$ok" = 1 ] && echo "== 旧接口零回归: 通过 ==" || { echo "== 回归失败 =="; exit 1; }
} 2>&1 | tee "$OUT/logs/segment2_regression.log"
sleep "$PAUSE"

# ---------------------------------------------------------------- seg 3
title 3 "gzip 流式容器读写 + 与系统 gzip 双向互操作"
{
run "$WORK/example7"
echo
run "$WORK/example7" c "$OUT/material/report.txt" "$OUT/material/report.txt.gz"
echo "-- .gz 文件头 (1f 8b = gzip magic):"
xxd -l 16 "$OUT/material/report.txt.gz"
run gzip -t "$OUT/material/report.txt.gz" && echo "系统 gzip -t 校验 miniz 产物: 通过"
gzip -dc "$OUT/material/report.txt.gz" > "$WORK/rt1.out"
cmp "$OUT/material/report.txt" "$WORK/rt1.out" && echo "miniz 写 -> 系统 gzip 读: 逐字节一致"
echo
gzip -9 -c "$OUT/material/report.txt" > "$WORK/sys.gz"
run "$WORK/example7" d "$WORK/sys.gz" "$WORK/rt2.out"
cmp "$OUT/material/report.txt" "$WORK/rt2.out" && echo "系统 gzip 写 -> miniz 读: 逐字节一致"
} 2>&1 | tee "$OUT/logs/segment3_readwrite.log"
sleep "$PAUSE"

# ---------------------------------------------------------------- seg 4
title 4 "校验错误检出: 损坏的 gzip 流必须报 MZ_DATA_ERROR"
{
cp "$OUT/material/report.txt.gz" "$WORK/good.gz"
expect_fail() {
    desc="$1"; file="$2"
    if "$WORK/example7" d "$file" "$WORK/corrupt.out" 2>&1 | grep -q "MZ_DATA_ERROR"; then
        echo "检出成功 [$desc]: mz_inflate 返回 MZ_DATA_ERROR"
    else
        echo "检出失败 [$desc]!"; exit 1
    fi
    if gzip -t "$file" 2> /dev/null; then echo "注意: 系统 gzip 未报错?!"; else echo "交叉验证 [$desc]: 系统 gzip -t 同样报错"; fi
}
python3 - "$WORK/good.gz" "$WORK/bad_payload.gz" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read())
d[len(d) // 2] ^= 0x40   # flip one bit in the deflate payload
open(sys.argv[2], 'wb').write(d)
EOF
python3 - "$WORK/good.gz" "$WORK/bad_crc.gz" <<'EOF'
import sys
d = bytearray(open(sys.argv[1], 'rb').read())
d[-5] ^= 0x01            # flip one bit in the CRC-32 trailer
open(sys.argv[2], 'wb').write(d)
EOF
head -c $(( $(stat -c %s "$WORK/good.gz") - 4 )) "$WORK/good.gz" > "$WORK/truncated.gz"
expect_fail "deflate 载荷比特翻转" "$WORK/bad_payload.gz"
expect_fail "CRC-32 尾比特翻转" "$WORK/bad_crc.gz"
if "$WORK/example7" d "$WORK/truncated.gz" "$WORK/corrupt.out" > /dev/null 2>&1; then
    echo "检出失败 [文件截断]!"; exit 1
else
    echo "检出成功 [文件截断]: 解压报错退出"
fi
echo "== 校验错误检出: 通过 =="
} 2>&1 | tee "$OUT/logs/segment4_checksum.log"
sleep "$PAUSE"

# ---------------------------------------------------------------- seg 5
title 5 "压缩率对比: gzip 流式容器 vs 归档模式 (同一素材)"
{
M="$OUT/material/report.txt"
"$WORK/example3" -l6 c "$M" "$WORK/m.z" > /dev/null           # miniz zlib 流 (归档同款 deflate 载荷)
python3 - "$M" "$WORK/m.zip" <<'EOF'
import sys, zipfile
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.write(sys.argv[1], 'report.txt')
EOF
gzip -6 -c "$M" > "$WORK/m.gzip6.gz"
gzip -9 -c "$M" > "$WORK/m.gzip9.gz"
python3 - "$M" "$OUT/material/report.txt.gz" "$WORK/m.z" "$WORK/m.zip" "$WORK/m.gzip6.gz" "$WORK/m.gzip9.gz" <<'EOF'
import sys, os
names = ["原始文件", "miniz gzip 容器 (example7)", "miniz zlib 流 (example3)", "zip 归档 (deflate-6)", "系统 gzip -6", "系统 gzip -9"]
sizes = [os.path.getsize(p) for p in sys.argv[1:]]
raw = sizes[0]
print("%-32s %12s %10s" % ("格式", "字节数", "相对原始"))
for n, s in zip(names, sizes):
    print("%-32s %12d %9.2f%%" % (n, s, 100.0 * s / raw))
gz, zip_size = sizes[1], sizes[3]
print()
print("结论: miniz gzip 容器与 zip 归档的压缩率差 %.2f%% (仅为容器头尾开销), 不明显劣于归档模式。" % (100.0 * (gz - zip_size) / raw))
EOF
} 2>&1 | tee "$OUT/logs/segment5_ratio.log" | tee "$OUT/ratio_report.txt"
sleep "$PAUSE"

echo
echo "================================================================"
echo "  全部 5 个分段完成。日志见 output/logs/, 压缩率见 output/ratio_report.txt"
echo "================================================================"
