#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

CANDALF_ROOT=$(dirname $(realpath $0))
. $CANDALF_ROOT/lib/candalf.sh

SERVER_CANDALF_FILE=${1:?"SERVER_CANDALF_FILE not set!"}

bootstrap "$SERVER_CANDALF_FILE"

echo -e "Applying spells from $SERVER_CANDALF_FILE\n"
candalf "$SERVER_CANDALF_FILE"
echo "Applying spells from $SERVER_CANDALF_FILE completed"
