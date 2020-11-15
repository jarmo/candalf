#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

function apply() {
  MIGRATION_FILE="${1:?"MIGRATION_FILE not set!"}"
  cd
  log "Started applying $MIGRATION_FILE"
  PROVISIONER_ROOT=${PROVISIONER_ROOT:="."}
  MIGRATION_PATH="$PROVISIONER_ROOT/$MIGRATION_FILE"
  if [[ -f "$MIGRATION_PATH.current" ]]; then
    if ! diff $MIGRATION_PATH.current $MIGRATION_PATH; then
      CURRENT_MIGRATION=$(cat $MIGRATION_PATH)
      _apply_migration $MIGRATION_PATH
      NOW=$(date +"%Y%m%d%H%M%S")
      echo -n $CURRENT_MIGRATION > $MIGRATION_PATH.$NOW
    else
      log "Skipping $MIGRATION_FILE since it has been applied already"
    fi
  else
    cat $MIGRATION_PATH
    _apply_migration $MIGRATION_PATH
  fi
  log "Applying of $MIGRATION_FILE complete\n"
}

function _apply_migration() {
  MIGRATION_PATH=$1
  ${MIGRATION_PATH}
  cp $MIGRATION_PATH $MIGRATION_PATH.current
}

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] - $1"
}
