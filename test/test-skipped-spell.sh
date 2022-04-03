#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_skipped_spell() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/timestamp.sh" "date +%s%N > ~/timestamp"
  create_spell_for "john" "$BOOK_PATH" "spells/timestamp.sh" "date +%s%N > ~/timestamp"

  candalf candalf-test "$BOOK_PATH"

  ROOT_FILE_CONTENT=$(file_content "/root/timestamp")
  assert_not_empty "$ROOT_FILE_CONTENT"

  USER_FILE_CONTENT=$(file_content "/home/john/timestamp")
  assert_not_empty "$USER_FILE_CONTENT"

  reset_log
  candalf candalf-test "$BOOK_PATH"

  assert_logged "Skipping.*timestamp\.sh since it has been cast already as the user root"
  assert_logged "Skipping.*timestamp\.sh since it has been cast already as the user john"

  assert_file_contains "/root/timestamp" "$ROOT_FILE_CONTENT"
  assert_file_contains "/home/john/timestamp" "$USER_FILE_CONTENT"

  echo "echo new-line > ~/foo" >> "$(dirname "$BOOK_PATH")/spells/timestamp.sh"

  reset_log
  candalf candalf-test "$BOOK_PATH"

  assert_not_logged "Skipping"

  assert_file_not_contains "/root/timestamp" "$ROOT_FILE_CONTENT"
  assert_file_not_contains "/home/john/timestamp" "$USER_FILE_CONTENT"

  assert_logged "Casting.*timestamp\.sh as the user root"
  assert_file_contains "/root/foo" "new-line"

  assert_logged "Casting.*timestamp\.sh as the user john"
  assert_file_contains "/home/john/foo" "new-line"
}

run_test "test_skipped_spell"
