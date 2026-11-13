#!/bin/bash
# Segment 6: existing deflate/stored paths show zero regression.
cd "$(dirname "$0")/../.." || exit 1

echo "=========================================================="
echo " Segment 6/6: Zero regression on the existing deflate path"
echo "=========================================================="
sleep 1

echo "+ miniz_tester archive roundtrips (same modes as test.sh, small tree)"
mkdir -p output/verify/tree/sub
for i in 1 2 3 4 5; do head -c $((i * 173)) /dev/urandom > output/verify/tree/file$i.bin; done
cp readme.md output/verify/tree/
cp miniz_zip.h output/verify/tree/sub/
for mode in "-v a" "-v -r a" "-v -b -r a" "-v -a a"; do
    echo "  + ./miniz_tester $mode output/verify/tree"
    ./miniz_tester $mode output/verify/tree 2>&1 | grep -E "Total source size|Error" | sed 's/^/    /'
done

echo "+ examples (deflate roundtrips)"
./example1 >/dev/null && echo "  example1 OK"
./example2 >/dev/null && echo "  example2 OK"
./example6 >/dev/null && echo "  example6 OK"
cp output/assets/content.bin /tmp/ex.bin
./example3 c /tmp/ex.bin /tmp/ex.z >/dev/null && ./example3 d /tmp/ex.z /tmp/ex.out >/dev/null && cmp /tmp/ex.bin /tmp/ex.out && echo "  example3 roundtrip OK"
./example5 c /tmp/ex.bin /tmp/ex5.z >/dev/null && ./example5 d /tmp/ex5.z /tmp/ex5.out >/dev/null && cmp /tmp/ex.bin /tmp/ex5.out && echo "  example5 roundtrip OK"

echo "+ bin/catch_tests (full suite)"
bin/catch_tests 2>&1 | tail -2

echo "+ git diff --stat (library change surface)"
git diff --stat -- miniz_zip.c miniz_zip.h

sleep 1
