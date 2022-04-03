#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeuo pipefail

SCRIPT_FILE="$(readlink -f "$0")"
SCRIPT_FILE_BASENAME=$(basename "$SCRIPT_FILE")
TEST_DIR=$(dirname "$SCRIPT_FILE")

# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=lib/colors.sh
. "${TEST_DIR}/../lib/colors.sh"

cd "$TEST_DIR"

for TEST_FILE in $(find . -name "test-*.sh" | shuf | grep -v "$SCRIPT_FILE_BASENAME")
do
    # shellcheck disable=SC1090
    . "$TEST_FILE"
done

echo -e "(${COLOR_GREY}${VAGRANT_BOX}${COLOR_END}) => ${COLOR_GREEN_BG}!!! ALL PASSED !!!${COLOR_END}"
