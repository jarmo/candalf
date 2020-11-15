#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

PROVISIONER_ROOT=$(dirname $(realpath $0))
. $PROVISIONER_ROOT/lib/provision.sh

SERVER_PROVISION_FILE="$1"

bootstrap "$SERVER_PROVISION_FILE"

echo -e "Provisioning $SERVER_PROVISION_FILE\n"
provision "$SERVER_PROVISION_FILE"
echo "Provisioning of $SERVER_PROVISION_FILE completed"
