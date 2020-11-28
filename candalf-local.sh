#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

CANDALF_ROOT=$(dirname $(realpath $0))
. $CANDALF_ROOT/lib/candalf-local.sh

CANDALF_FILE=${1:?"CANDALF_FILE not set!"}

bootstrap "$CANDALF_FILE"

echo -e "Applying spells from $CANDALF_FILE\n"
candalf "$CANDALF_FILE"
echo "Applying spells from $CANDALF_FILE completed"
