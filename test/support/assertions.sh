#!/usr/bin/env bash

set -Eeuo pipefail

TEST_DIR="${TEST_DIR:?"TEST_DIR is required!"}"
# shellcheck source=lib/colors.sh
. "${TEST_DIR}/../lib/colors.sh"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"

assert_logged() {
  _log "$@"
  trap _enable_log RETURN

  REGEXP="${1:?"REGEXP is required!"}"

  vm_exec "sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' /var/log/candalf.log | grep -qE '$REGEXP'"
}

assert_not_logged() {
  _log "$@"
  trap _enable_log RETURN

  ! assert_logged "$@"
}

assert_file_content() {
  _log "$@"
  trap _enable_log RETURN

  FILE_PATH="${1:?"FILE_PATH is required!"}"
  EXPECTED_CONTENT="${2:?"EXPECTED_CONTENT is required!"}"

  ACTUAL_CONTENT=$(file_content "${FILE_PATH}")

  test "$EXPECTED_CONTENT" = "$ACTUAL_CONTENT"
}

assert_file_contains() {
  _log "$@"
  trap _enable_log RETURN

  FILE_PATH="${1:?"FILE_PATH is required!"}"
  REGEXP="${2:?"REGEXP is required!"}"

  vm_exec "grep -qE '$REGEXP' '$FILE_PATH'"
}

assert_file_not_contains() {
  _log "$@"
  trap _enable_log RETURN

  ! assert_file_contains "$@"
}

assert_file_exists() {
  _log "$@"
  trap _enable_log RETURN

  FILE_PATH="${1:?"FILE_PATH is required!"}"

  vm_exec "test -e $FILE_PATH"
}

assert_file_not_exists() {
  _log "$@"
  trap _enable_log RETURN

  ! assert_file_exists "$@"
}

assert_not_empty() {
  _log "$@"
  trap _enable_log RETURN

  VALUE="$1"

  test "$VALUE" != ""
}

_log() {
  if [[ "$DISABLE_ASSERT_LOG" != 1 ]]; then
    echo -e "${COLOR_YELLOW}${FUNCNAME[1]} ${*}${COLOR_END}"
    DISABLE_ASSERT_LOG=1
  fi
}

_enable_log() {
  DISABLE_ASSERT_LOG=0
}

_enable_log

