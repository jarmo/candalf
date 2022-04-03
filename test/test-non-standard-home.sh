#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_non_standard_home() {
  vm_exec "mkdir -p /var/lib/john && chown john:john /var/lib/john && ( usermod --home /var/lib/john john 2>/dev/null || pw usermod john -d /var/lib/john )"
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/whoami.sh" "whoami > ~/me"
  create_spell_for "john" "$BOOK_PATH" "spells/whoami.sh" "whoami > ~/me"

  candalf candalf.test "$BOOK_PATH"

  assert_file_contains "/root/me" "root"
  assert_file_contains "/var/lib/john/me" "john"
}

run_test "test_non_standard_home"
