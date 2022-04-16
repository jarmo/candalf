#!/usr/bin/env bash

set -Eeuo pipefail

VAGRANT_BOX="${VAGRANT_BOX:-"generic/ubuntu2110"}"

TEST_DIR="${TEST_DIR:?"TEST_DIR is required!"}"
TRAPS_SET="${TRAPS_SET:-""}"

# shellcheck source=test/support/vm.sh
. "${TEST_DIR}/support/vm.sh"
# shellcheck source=lib/colors.sh
. "${TEST_DIR}/../lib/colors.sh"

before_all() {
  vm_prepare
}

candalf() {
  CANDALF_SSH_CONFIG_PATH="$TEST_DIR/support/ssh/config" \
    "$TEST_DIR"/../candalf.sh "${@}"
}

before_each() {
  cd "$TEST_DIR"

  [[ ! "$TRAPS_SET" ]] && set_traps
  vm_restore || before_all
}

after_all() {
  cd "$TEST_DIR"
  vm_destroy
}

set_traps() {
  trap fail_test INT ERR
  trap after_all EXIT
  TRAPS_SET=1
}

fail_test() {
  TEST_NAME="${TEST_NAME:-""}"
  if [[ "$TEST_NAME" != "" ]]; then
    echo -e "(${COLOR_GREY}${VAGRANT_BOX}${COLOR_END}) => ${COLOR_RED_BG}!!! FAILED !!!${COLOR_END} ${COLOR_YELLOW}${TEST_NAME}${COLOR_END}"
  else
    echo -e "(${COLOR_GREY}${VAGRANT_BOX}${COLOR_END}) => ${COLOR_RED_BG}!!! FAILED !!!${COLOR_END}"
  fi
  exit 1
}

create_book() {
  BOOK_DIR_PATH="$TEST_DIR/.test-book"
  rm -rf "$BOOK_DIR_PATH"
  mkdir -p "$BOOK_DIR_PATH"

  BOOK_PATH="${BOOK_DIR_PATH}/book.sh"

  cat << EOF > "${BOOK_PATH}"
#!/usr/bin/env bash

test "\$VERBOSE" && set -x
set -Eeo pipefail

. "\${CANDALF_ROOT:="."}"/lib/cast.sh
EOF
  chmod +x "${BOOK_PATH}"

  echo "${BOOK_PATH}"
}

create_spell() {
  create_spell_for "" "$@"
}

create_spell_for() {
  CAST_AS_USER="$1"
  BOOK_PATH="${2:?"BOOK_PATH is required!"}"
  SPELL_PATH="${3:?"SPELL_PATH is required!"}"
  SPELL_CONTENT="${4:?"SPELL_CONTENT is required!"}"
  CAST_FLAGS="${5:-""}"
  BOOK_DIR=$(dirname "${BOOK_PATH}")
  SPELL_FULL_PATH="$BOOK_DIR/$SPELL_PATH"

  mkdir -p "$(dirname "$SPELL_FULL_PATH")"
  cat << EOF > "${SPELL_FULL_PATH}"
#!/usr/bin/env bash

test "\$VERBOSE" && set -x
set -Eeo pipefail

${SPELL_CONTENT}
EOF
  chmod +x "${SPELL_FULL_PATH}"

  if [[ "$CAST_AS_USER" = "" ]]; then
    add_spell_to_book "$SPELL_PATH" "$BOOK_PATH" "$CAST_FLAGS"
  else
    add_spell_to_book_for "$CAST_AS_USER" "$SPELL_PATH" "$BOOK_PATH" "$CAST_FLAGS"
  fi
}

add_spell_to_book() {
  SPELL_PATH="${1:?"SPELL_PATH is required!"}"
  BOOK_PATH="${2:?"BOOK_PATH is required!"}"
  CAST_FLAGS="${3:-""}"

  echo "$CAST_FLAGS cast $SPELL_PATH" >> "$BOOK_PATH"
}

add_spell_to_book_for() {
  CAST_AS_USER="${1:?"CAST_AS_USER is required!"}"
  SPELL_PATH="${2:?"SPELL_PATH is required!"}"
  BOOK_PATH="${3:?"BOOK_PATH is required!"}"
  CAST_FLAGS="${4:-""}"

  echo "$CAST_FLAGS cast_as $CAST_AS_USER $SPELL_PATH" >> "$BOOK_PATH"
}

file_content() {
  FILE_PATH="${1:?"FILE_PATH is required!"}"

  vm_exec "cat ${FILE_PATH}"
}

reset_log() {
  vm_exec "rm -rf /var/log/candalf.log"
}

run_test() {
  TEST_NAME="${1:?"TEST_NAME is required!"}"

  before_each
  echo -e "(${COLOR_GREY}${VAGRANT_BOX}${COLOR_END}) => ${COLOR_GREEN}!!! RUNNING !!!${COLOR_END} ${COLOR_YELLOW}${TEST_NAME}${COLOR_END}"
  ${TEST_NAME}
  echo -e "(${COLOR_GREY}${VAGRANT_BOX}${COLOR_END}) => ${COLOR_GREEN_BG}!!! PASSED !!!${COLOR_END} ${COLOR_YELLOW}${TEST_NAME}${COLOR_END}"
}

