#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_cast_never() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/timestamp.sh" "date +%s%N > ~/timestamp" "CAST_NEVER=1"
  create_spell_for "john" "$BOOK_PATH" "spells/timestamp.sh" "date +%s%N > ~/timestamp" "CAST_NEVER=1"

  candalf candalf-test "$BOOK_PATH"

  assert_file_not_exists "/root/timestamp"
  assert_logged "Casting.*timestamp\.sh completed as the user root"

  assert_file_not_exists "/home/john/timestamp"
  assert_logged "Casting.*timestamp\.sh completed as the user john"
}

run_test "test_cast_never"
