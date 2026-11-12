#!/bin/bash
# Segment 2: boundary behavior, verified through the repo's own catch2 tests.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "Segment 2/7: boundary behavior (65535/65536 entries, crossing 4GB, over-limit error codes)"

CT="$REPO_ROOT/bin/catch_tests"
[ -x "$CT" ] || CT="$REPO_ROOT/build/bin/catch_tests"

echo "* writer switches to zip64 automatically past classic limits"
"$CT" "Zip writer automatically switches to zip64 past classic limits"
echo
echo "* reader rejects archives beyond zip64 practical limits with error codes"
"$CT" "Zip reader rejects archives beyond zip64 practical limits"

pause
