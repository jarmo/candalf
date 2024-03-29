#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

. "$CANDALF_ROOT"/lib/colors.sh
# shellcheck source=lib/candalf-env.sh
. "$CANDALF_ROOT"/lib/candalf-env.sh

function cast() {
  SPELL_FILE="${1:?"SPELL_FILE not set!"}"
  CANDALF_ROOT=${CANDALF_ROOT:?"CANDALF_ROOT not set!"}
  SPELL_PATH="$(realpath "$CANDALF_SPELLS_ROOT/$SPELL_FILE")"
  CAST_ALWAYS="${CAST_ALWAYS:-""}"
  CAST_NEVER="${CAST_NEVER:-""}"
  log "${COLOR_GREEN}Casting${COLOR_END} spell ${COLOR_YELLOW}$SPELL_PATH${COLOR_END} as the user ${COLOR_MAGENTA}$USER${COLOR_END}"
  if [[ "$CAST_ALWAYS" != "1" && -f "$SPELL_PATH.current" ]]; then
    if ! diff "$SPELL_PATH".current "$SPELL_PATH"; then
      CURRENT_SPELL=$(cat "$SPELL_PATH")
      _cast "$SPELL_PATH"
      NOW=$(date +"%Y%m%d%H%M%S")
      echo -n "$CURRENT_SPELL" > "$SPELL_PATH.$NOW"
    else
      log "${COLOR_GREY}Skipping${COLOR_END} spell ${COLOR_YELLOW}$SPELL_PATH${COLOR_END} since it has been cast already as the user ${COLOR_MAGENTA}$USER${COLOR_END}"
    fi
  else
    cat "$SPELL_PATH"
    _cast "$SPELL_PATH"
  fi
  log "${COLOR_GREEN_BG}Casting${COLOR_END} spell ${COLOR_YELLOW}$SPELL_PATH${COLOR_END} completed as the user ${COLOR_MAGENTA}$USER${COLOR_END}\n"
}

function cast_as() {
  CAST_USER="${1:?"CAST_USER not set!"}"
  SPELL_FILE="${2:?"SPELL_FILE not set!"}"
  CANDALF_ROOT=${CANDALF_ROOT:="."}
  CANDALF_DIR_NAME=$(basename "$CANDALF_ROOT")
  USER_CANDALF_ROOT="$(eval echo ~"$CAST_USER")/$CANDALF_DIR_NAME"
  SPELL_BOOK_NAME="$(basename "$CANDALF_SPELLS_ROOT")"
  USER_CANDALF_SPELLS_ROOT="$USER_CANDALF_ROOT/$SPELL_BOOK_NAME"
  CAST_ALWAYS="${CAST_ALWAYS:-""}"
  CAST_NEVER="${CAST_NEVER:-""}"
  cd "$CANDALF_ROOT"
  mkdir -p "$USER_CANDALF_ROOT/lib"
  rsync -ac lib/cast.sh lib/candalf-env.sh lib/colors.sh "$USER_CANDALF_ROOT/lib"
  rsync -Rac "$SPELL_BOOK_NAME/$SPELL_FILE" "$USER_CANDALF_ROOT"
  chown -R "$CAST_USER":"$CAST_USER" "$USER_CANDALF_ROOT"
  cd - >/dev/null

  eval "$(candalfEnv)"

  # shellcheck disable=SC2154
  sudo -iHu "$CAST_USER" env "${candalfEnvVars[@]}" CANDALF_ROOT="$USER_CANDALF_ROOT" CANDALF_SPELLS_ROOT="$USER_CANDALF_SPELLS_ROOT" CAST_ALWAYS="$CAST_ALWAYS" CAST_NEVER="$CAST_NEVER" VERBOSE="$VERBOSE" HISTFILE=/dev/null \
    bash -c ". $CANDALF_DIR_NAME/lib/cast.sh && cast $(printf "%q" "$SPELL_FILE")"
}

function _cast() {
  if [[ "$CANDALF_DRY_RUN" != "1" ]]; then
    SPELL_PATH=$1
    if [[ "$CAST_NEVER" != 1 ]]; then
      cd
      echo
      trap log_error INT ERR
      "${SPELL_PATH}"
      trap - INT ERR
      echo
    else
      log "Spell was NOT cast due to ${COLOR_YELLOW_BG}CAST_NEVER=1${COLOR_END} attribute"
    fi
    cp "$SPELL_PATH" "$SPELL_PATH".current
  else
    echo
    log "Spell was NOT cast due to ${COLOR_YELLOW_BG}dry-run${COLOR_END} mode being enabled"
  fi
}

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] - $1"
}

function log_error() {
  log "${COLOR_RED}Failed${COLOR_END} to cast spell ${COLOR_YELLOW}$SPELL_PATH${COLOR_END} as the user ${COLOR_MAGENTA}$USER${COLOR_END}\n"
  exit 1
}

