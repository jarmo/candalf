#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

function cast() {
  SPELL_FILE="${1:?"SPELL_FILE not set!"}"
  cd
  CANDALF_ROOT=${CANDALF_ROOT:="."}
  SPELL_PATH="$(realpath "$CANDALF_ROOT/$SPELL_FILE")"
  log "Casting $SPELL_PATH as the user $USER"
  if [[ -f "$SPELL_PATH.current" ]]; then
    if ! diff $SPELL_PATH.current $SPELL_PATH; then
      CURRENT_SPELL=$(cat $SPELL_PATH)
      _cast $SPELL_PATH
      NOW=$(date +"%Y%m%d%H%M%S")
      echo -n $CURRENT_SPELL > $SPELL_PATH.$NOW
    else
      log "Skipping $SPELL_PATH since it has been cast already as the user $USER"
    fi
  else
    cat $SPELL_PATH
    _cast $SPELL_PATH
  fi
  log "Casting $SPELL_PATH completed as the user $USER\n"
}

function cast_as() {
  CAST_USER="${1:?"CAST_USER not set!"}"
  SPELL_FILE="${2:?"SPELL_FILE not set!"}"
  CANDALF_DIR_NAME=$(basename $CANDALF_ROOT)
  cd $CANDALF_ROOT
  rsync -Rac lib/cast.sh "$SPELL_FILE" "/home/$CAST_USER/$CANDALF_DIR_NAME"
  cd

  su - "$CAST_USER" -c "bash -c 'export SERVER_HOSTNAME=$SERVER_HOSTNAME; export CANDALF_ROOT=$CANDALF_REMOTE_ROOT; export VERBOSE=$VERBOSE; . $CANDALF_DIR_NAME/lib/cast.sh; cast $CANDALF_DIR_NAME/$SPELL_FILE'"
}

function _cast() {
  SPELL_PATH=$1
  ${SPELL_PATH}
  cp $SPELL_PATH $SPELL_PATH.current
}

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] - $1"
}
