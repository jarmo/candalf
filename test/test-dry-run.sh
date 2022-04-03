#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_dry_run() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/text.sh" "echo 'hello root'> ~/text"
  create_spell_for "john" "$BOOK_PATH" "spells/text.sh" "echo 'hello john' > ~/text"

  candalf --dry-run candalf.test "$BOOK_PATH"

  assert_file_not_exists "/root/text"
  assert_file_not_exists "/home/john/text"

  assert_logged "Casting spell .*text\.sh completed as the user root"
  assert_logged "Casting spell .*text\.sh completed as the user john"
}

run_test "test_dry_run"
