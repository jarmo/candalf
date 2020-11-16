#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

CANDALF_ROOT=$(dirname $(realpath $0))
. $CANDALF_ROOT/lib/candalf.sh

SERVER_CANDALF_FILE="$1"

bootstrap "$SERVER_CANDALF_FILE"

echo -e "Applying spells to $SERVER_CANDALF_FILE\n"
candalf "$SERVER_CANDALF_FILE"
echo "Applying spells to $SERVER_CANDALF_FILE completed"
