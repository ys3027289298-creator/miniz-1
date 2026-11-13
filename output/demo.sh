#!/usr/bin/env bash
# Segmented, non-interactive demo of zstd (method 93) read-side support in the
# miniz zip reader. Recorded with: asciinema rec -c "bash output/demo.sh" output/demo.cast
set -u
cd "$(dirname "$0")/.."
exec > >(tee output/results.log) 2>&1

SEG=0
seg() { SEG=$((SEG + 1)); echo; echo "########## 段 ${SEG}: $1 ##########"; sleep 2; }

seg "改动概览 (读侧小改数处, 写侧不动)"
git diff --stat
sleep 1

seg "构建 (仓库自带 cmake 入口)"
cmake --build build -j 2>&1 | tail -n 2
sleep 1

seg "生成小体积 zstd 测试素材 (output/)"
./output/gen_assets
ls -l output/*.zip
head -c 200 output/zstd_small.zip >output/zstd_cut.zip
sleep 1

seg "正确性: 三条读取路径解压校验 (heap / callback / iter)"
for m in heap file iter; do
    ./output/verify_zstd output/zstd_small.zip hello.txt output/ref_hello.txt "$m"
done
sleep 1

seg "内存受控: 32MiB 条目流式解压 (归档仅 ~583KB)"
ls -l output/zstd_big.zip
for m in file iter; do
    /usr/bin/time -v ./output/verify_zstd output/zstd_big.zip big.bin output/ref_big.bin "$m" 2>&1 |
        grep -E "entry=|Maximum resident|^OK"
done
sleep 1

seg "错误输入拒绝: 帧损坏 / 帧截断 / 整包截断"
./output/verify_zstd output/zstd_corrupt.zip hello.txt output/ref_hello.txt heap --expect-fail
./output/verify_zstd output/zstd_trunc.zip hello.txt output/ref_hello.txt file --expect-fail
./output/verify_zstd output/zstd_cut.zip hello.txt output/ref_hello.txt iter --expect-fail
sleep 1

seg "写侧回归: 仓库自带 example2 与 catch 测试套件"
(cd /tmp && "$OLDPWD/bin/example2" 2>&1 | tail -n 1)
bin/catch_tests 2>&1 | grep "All tests passed"
echo
echo "全部检查完成"
