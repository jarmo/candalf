#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_bash_history_localhost() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/bash-history.sh" "echo 'this shall not end up in the history'"
  create_spell_for "john" "$BOOK_PATH" "spells/bash-history.sh" "echo 'this shall not end up in the history'"

  candalf_local "/candalf/test/.test-book/$(basename "$BOOK_PATH")"
  vm_exec "touch /root/.bash_history /home/john/.bash_history"

  assert_file_not_contains "/root/.bash_history" "this shall not end up in the history"
  assert_file_not_contains "/home/john/.bash_history" "this shall not end up in the history"
}

run_test_using_interactive_shell "test_bash_history_localhost"
