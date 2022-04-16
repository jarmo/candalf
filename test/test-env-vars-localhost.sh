#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_env_vars_localhost() {
  BOOK_PATH=$(create_book)
  create_spell "$BOOK_PATH" "spells/env-vars.sh" "env > ~/env.vars; echo -n \$CANDALF_TEST_ENV_VAR > ~/candalf.env; echo -n \$CANDALF_ANOTHER_TEST_ENV_VAR > ~/candalf-another.env"
  create_spell_for "john" "$BOOK_PATH" "spells/env-vars.sh" "env > ~/env.vars; echo -n \$CANDALF_TEST_ENV_VAR > ~/candalf.env; echo -n \$CANDALF_ANOTHER_TEST_ENV_VAR > ~/candalf-another.env"

  vm_exec "sudo -H CANDALF_TEST_ENV_VAR='from-candalf-test' \
    CANDALF_ANOTHER_TEST_ENV_VAR='variable with spaces' \
    FOO_BAR='maybe-passed-var' \
    /candalf/candalf.sh localhost /candalf/test/test-book/$(basename "$BOOK_PATH")"

  assert_file_contains "/root/env.vars" "from-candalf-test"
  assert_file_contains "/root/env.vars" "variable with spaces"
  assert_file_contains "/root/env.vars" "maybe-passed-var"
  assert_file_content "/root/candalf.env" "from-candalf-test"
  assert_file_content "/root/candalf-another.env" "variable with spaces"

  assert_file_contains "/home/john/env.vars" "from-candalf-test"
  assert_file_contains "/home/john/env.vars" "variable with spaces"
  assert_file_not_contains "/home/john/env.vars" "maybe-passed-var"
  assert_file_content "/home/john/candalf.env" "from-candalf-test"
  assert_file_content "/home/john/candalf-another.env" "variable with spaces"
}

run_test "test_env_vars_localhost"
