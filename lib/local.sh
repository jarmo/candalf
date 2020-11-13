#!/bin/bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

function provision() {
  SERVER_PROVISION_FILE="${1:?"server provision file not set!"}"
  SERVER_HOSTNAME=$(basename $SERVER_PROVISION_FILE | rev | cut -d "." -f2- | rev)
  VERBOSE="${VERBOSE:-""}"
  rsync -qRavc $SERVER_PROVISION_FILE lib/remote.sh $(grep -w "apply" $SERVER_PROVISION_FILE | cut -d " " -f 2) -e "ssh -q" $SERVER_HOSTNAME:.provision
  ssh -o ConnectTimeout=5 -o ConnectionAttempts=2 -qtt "$SERVER_HOSTNAME" "export SERVER_HOSTNAME=$SERVER_HOSTNAME; export VERBOSE=$VERBOSE; cd .provision && \$SHELL $SERVER_PROVISION_FILE"
}

