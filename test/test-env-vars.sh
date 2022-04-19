#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_env_vars() {
  BOOK_PATH=$(create_book)
  echo "export CANDALF_YET_ANOTHER_VAR=from-export" >> "$BOOK_PATH"
  echo "CANDALF_YET_ANOTHER_OTHER_VAR=from-not-export" >> "$BOOK_PATH"

  create_spell "$BOOK_PATH" "spells/env-vars.sh" "
  env > ~/env.vars
  echo -n \$CANDALF_TEST_ENV_VAR > ~/candalf.env
  echo -n \$CANDALF_ANOTHER_TEST_ENV_VAR > ~/candalf-another.env
  echo -n \$CANDALF_YET_ANOTHER_VAR > ~/candalf-yet-another.env"

  create_spell_for "john" "$BOOK_PATH" "spells/env-vars.sh" "
  env > ~/env.vars
  echo -n \$CANDALF_TEST_ENV_VAR > ~/candalf.env
  echo -n \$CANDALF_ANOTHER_TEST_ENV_VAR > ~/candalf-another.env
  echo -n \$CANDALF_YET_ANOTHER_VAR > ~/candalf-yet-another.env"

  CANDALF_TEST_ENV_VAR="from-candalf-test" \
    CANDALF_ANOTHER_TEST_ENV_VAR="variable with spaces" \
    FOO_BAR="not-passed-var" \
    candalf candalf.test "$BOOK_PATH"

  assert_file_contains "/root/env.vars" "from-candalf-test"
  assert_file_contains "/root/env.vars" "variable with spaces"
  assert_file_contains "/root/env.vars" "from-export"
  assert_file_not_contains "/root/env.vars" "not-passed-var"
  assert_file_not_contains "/root/env.vars" "from-not-export"
  assert_file_content "/root/candalf.env" "from-candalf-test"
  assert_file_content "/root/candalf-another.env" "variable with spaces"
  assert_file_content "/root/candalf-yet-another.env" "from-export"

  assert_file_contains "/home/john/env.vars" "from-candalf-test"
  assert_file_contains "/home/john/env.vars" "variable with spaces"
  assert_file_contains "/home/john/env.vars" "from-export"
  assert_file_not_contains "/home/john/env.vars" "not-passed-var"
  assert_file_not_contains "/home/john/env.vars" "from-not-export"
  assert_file_content "/home/john/candalf.env" "from-candalf-test"
  assert_file_content "/home/john/candalf-another.env" "variable with spaces"
  assert_file_content "/home/john/candalf-yet-another.env" "from-export"
}

run_test "test_env_vars"
