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
  create_spell "$BOOK_PATH" "spells/env-vars.sh" "env > ~/env.vars"
  create_spell_for "john" "$BOOK_PATH" "spells/env-vars.sh" "env > ~/env.vars"

  CANDALF_TEST_ENV_VAR="from-candalf-test" \
    FOO_BAR="not-passed-var" \
    candalf candalf-test "$BOOK_PATH"

  assert_file_contains "/root/env.vars" "from-candalf-test"
  assert_file_not_contains "/root/env.vars" "not-passed-var"

  assert_file_contains "/home/john/env.vars" "from-candalf-test"
  assert_file_not_contains "/home/john/env.vars" "not-passed-var"
}

run_test "test_env_vars"
