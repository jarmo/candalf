#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_failing_spell() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/failing.sh" "totally-invalid-command"
  create_spell "$BOOK_PATH" "spells/env.sh" "env"

  candalf candalf.test "$BOOK_PATH" || true

  assert_logged "Failed.*failing\.sh"
  assert_not_logged "env\.sh"
}

test_failing_spell_for_user() {
  BOOK_PATH=$(create_book)
  create_spell_for "john" "$BOOK_PATH" "spells/failing.sh" "totally-invalid-command"
  create_spell_for "john" "$BOOK_PATH" "spells/env.sh" "env"

  candalf candalf.test "$BOOK_PATH" || true

  assert_logged "Failed.*failing\.sh"
  assert_not_logged "env\.sh"
}

run_test "test_failing_spell"
run_test "test_failing_spell_for_user"
