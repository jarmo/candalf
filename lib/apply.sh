#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

function apply() {
  MIGRATION_FILE="${1:?"MIGRATION_FILE not set!"}"
  cd
  PROVISIONER_ROOT=${PROVISIONER_ROOT:="."}
  MIGRATION_PATH="$(realpath "$PROVISIONER_ROOT/$MIGRATION_FILE")"
  log "Started applying $MIGRATION_PATH as user $USER"
  if [[ -f "$MIGRATION_PATH.current" ]]; then
    if ! diff $MIGRATION_PATH.current $MIGRATION_PATH; then
      CURRENT_MIGRATION=$(cat $MIGRATION_PATH)
      _apply_migration $MIGRATION_PATH
      NOW=$(date +"%Y%m%d%H%M%S")
      echo -n $CURRENT_MIGRATION > $MIGRATION_PATH.$NOW
    else
      log "Skipping $MIGRATION_PATH since it has been applied already as user $USER"
    fi
  else
    cat $MIGRATION_PATH
    _apply_migration $MIGRATION_PATH
  fi
  log "Applying of $MIGRATION_PATH complete as user $USER\n"
}

function apply_as() {
  APPLY_USER="${1:?"USER not set!"}"
  MIGRATION_FILE="${2:?"MIGRATION_FILE not set!"}"
  cd $PROVISIONER_ROOT
  rsync -Rac lib/apply.sh "$MIGRATION_FILE" "/home/$APPLY_USER"/$(basename "$PROVISIONER_ROOT")
  cd

  su - "$APPLY_USER" -c "bash -c 'export SERVER_HOSTNAME=$SERVER_HOSTNAME; export PROVISIONER_ROOT=$PROVISIONER_REMOTE_ROOT; export VERBOSE=$VERBOSE; . $(basename $PROVISIONER_ROOT)/lib/apply.sh; apply $(basename $PROVISIONER_ROOT)/$MIGRATION_FILE'"
}

function _apply_migration() {
  MIGRATION_PATH=$1
  ${MIGRATION_PATH}
  cp $MIGRATION_PATH $MIGRATION_PATH.current
}

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] - $1"
}
