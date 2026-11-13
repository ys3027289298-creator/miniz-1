#!/bin/bash
# Segment 1: build everything using the repo's own entry points.
cd "$(dirname "$0")/../.." || exit 1

echo "================================================================"
echo " Segment 1/6: Build (amalgamate.sh + miniz_tester + catch_tests)"
echo "================================================================"
sleep 1

echo "+ create miniz_export.h (same as test.sh)"
printf '#ifndef MINIZ_EXPORT\n#define MINIZ_EXPORT\n#endif\n' > miniz_export.h

echo "+ SKIPTESTS=1 bash amalgamate.sh"
SKIPTESTS=1 bash amalgamate.sh 2>&1 | tail -1

echo "+ g++ tests/miniz_tester.cpp tests/timer.cpp amalgamation/miniz.c -o miniz_tester"
g++ tests/miniz_tester.cpp tests/timer.cpp amalgamation/miniz.c -o miniz_tester -I. -ggdb -O2 2>/dev/null

echo "+ gcc examples/exampleN.c (1..6)"
for i in 1 2 3 4 5 6; do
    gcc examples/example$i.c amalgamation/miniz.c -o example$i -lm -I. -ggdb 2>/dev/null || exit 1
done

echo "+ cmake --build /tmp/miniz-build --target catch_tests"
cmake -S . -B /tmp/miniz-build -G "Unix Makefiles" >/dev/null 2>&1
cmake --build /tmp/miniz-build --target catch_tests -j4 2>&1 | tail -1

echo "build OK"
sleep 1
