#!/bin/bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

function apply() {
  MIGRATION_FILE="${1:?"MIGRATION_FILE not set!"}"
  log "Started applying $MIGRATION_FILE"
  if [[ -f "$MIGRATION_FILE.head" ]]; then
    if ! git --no-pager diff --no-index --minimal $MIGRATION_FILE.head $MIGRATION_FILE; then
      NOW=$(date +"%Y%m%d%H%M%S")
      mv -f $MIGRATION_FILE.head $MIGRATION_FILE.$NOW
      _apply_migration $MIGRATION_FILE
    else
      log "Skipping $MIGRATION_FILE since it has been already applied"
    fi
  else
    _apply_migration $MIGRATION_FILE
  fi
  log "Applying of $MIGRATION_FILE complete\n"
}

function _apply_migration() {
  MIGRATION_FILE=$1
  ${MIGRATION_FILE}
  cp $MIGRATION_FILE $MIGRATION_FILE.head
}

function log() {
  echo -e "$(date) - $1"
}
