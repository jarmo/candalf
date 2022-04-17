#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_cast_always() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/random.sh" "echo \$RANDOM > ~/random" "CAST_ALWAYS=1"
  create_spell_for "john" "$BOOK_PATH" "spells/random.sh" "echo \$RANDOM > ~/random" "CAST_ALWAYS=1"

  candalf candalf.test "$BOOK_PATH"

  ROOT_FILE_CONTENT=$(file_content "/root/random")
  assert_not_empty "$ROOT_FILE_CONTENT"

  USER_FILE_CONTENT=$(file_content "/home/john/random")
  assert_not_empty "$USER_FILE_CONTENT"

  candalf candalf.test "$BOOK_PATH"

  assert_file_not_contains "/root/random" "$ROOT_FILE_CONTENT"
  assert_file_not_contains "/home/john/random" "$USER_FILE_CONTENT"
}

run_test "test_cast_always"
