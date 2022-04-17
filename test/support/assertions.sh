#!/usr/bin/env bash

set -Eeuo pipefail

TEST_DIR="${TEST_DIR:?"TEST_DIR is required!"}"
# shellcheck source=lib/colors.sh
. "${TEST_DIR}/../lib/colors.sh"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"

assert_not_logged() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  REGEXP="${1:?"REGEXP is required!"}"

  ! vm_exec "sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' /var/log/candalf.log | grep -qE '$REGEXP'"
}

assert_logged() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  REGEXP="${1:?"REGEXP is required!"}"

  vm_exec "sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' /var/log/candalf.log | grep -qE '$REGEXP'"
}

assert_file_content() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  FILE_PATH="${1:?"FILE_PATH is required!"}"
  EXPECTED_CONTENT="${2:?"EXPECTED_CONTENT is required!"}"

  ACTUAL_CONTENT=$(file_content "${FILE_PATH}")

  test "$EXPECTED_CONTENT" = "$ACTUAL_CONTENT"
}

assert_file_contains() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  FILE_PATH="${1:?"FILE_PATH is required!"}"
  REGEXP="${2:?"REGEXP is required!"}"

  vm_exec "grep -qE '$REGEXP' '$FILE_PATH'"
}

assert_file_not_contains() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  FILE_PATH="${1:?"FILE_PATH is required!"}"
  REGEXP="${2:?"REGEXP is required!"}"

  ! vm_exec "grep -qE '$REGEXP' '$FILE_PATH'"
}

assert_file_exists() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  FILE_PATH="${1:?"FILE_PATH is required!"}"

  vm_exec "test -e $FILE_PATH"
}

assert_file_not_exists() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  FILE_PATH="${1:?"FILE_PATH is required!"}"

  ! vm_exec "test -e $FILE_PATH"
}

assert_not_empty() {
  echo -e "${COLOR_YELLOW}${FUNCNAME[0]} ${*}${COLOR_END}"

  VALUE="$1"

  test "$VALUE" != ""
}
