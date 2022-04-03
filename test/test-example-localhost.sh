#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

TEST_DIR="${TEST_DIR:-"$(dirname "$(readlink -f "$0")")"}"
# shellcheck source=test/support/functions.sh
. "${TEST_DIR}/support/functions.sh"
# shellcheck source=test/support/assertions.sh
. "${TEST_DIR}/support/assertions.sh"

test_example_localhost() {
  vm_exec "sudo -H /candalf/candalf.sh localhost /candalf/example/example-book.sh"

  assert_logged "Casting.*completed"
  assert_not_logged "(Failed|Skipping)"

  assert_file_content "/root/today" "$(date +"%Y-%m-%d")"
  assert_file_content "/root/me" "root"
  assert_file_content "/home/john/me" "john"

  assert_file_not_exists "/root/upgrade-done"
}

test_example_local_ip() {
  vm_exec "sudo -H /candalf/candalf.sh 127.0.0.1 /candalf/example/example-book.sh"

  assert_logged "Casting.*completed"
  assert_not_logged "(Failed|Skipping)"

  assert_file_content "/root/today" "$(date +"%Y-%m-%d")"
  assert_file_content "/root/me" "root"
  assert_file_content "/home/john/me" "john"

  assert_file_not_exists "/root/upgrade-done"
}

run_test "test_example_localhost"
run_test "test_example_local_ip"
