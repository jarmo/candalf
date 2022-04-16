#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_spaces_in_files_localhost() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/spell with space.sh" "echo done > ~/done"
  create_spell_for "john" "$BOOK_PATH" "spells/spell with space.sh" "echo done > ~/done"
  NEW_BOOK_PATH="$(dirname "$BOOK_PATH")/book with space.sh"
  mv "$BOOK_PATH" "$NEW_BOOK_PATH"

  vm_exec "sudo -H /candalf/candalf.sh localhost \"/candalf/test/.test-book/$(basename "$NEW_BOOK_PATH")\""

  assert_file_content "/root/done" "done"
  assert_file_content "/home/john/done" "done"
}

run_test "test_spaces_in_files_localhost"
