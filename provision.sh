#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

SCRIPT_ROOT=$(dirname $(realpath $0))
. $SCRIPT_ROOT/lib/local.sh

SERVER_PROVISION_FILE="$1"

bootstrap "$SERVER_PROVISION_FILE"

echo -e "Provisioning $SERVER_PROVISION_FILE\n"
provision "$SERVER_PROVISION_FILE"
echo "Provisioning of $SERVER_PROVISION_FILE completed"
