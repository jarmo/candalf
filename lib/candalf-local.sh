#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

CANDALF_REMOTE_ROOT=$HOME/.candalf
SSH_OUTPUT_FLAG=$([ -z "$VERBOSE" ] && echo "-q" || echo "-v")

candalf() {
  SPELL_BOOK="${1:?"SPELL_BOOK not set!"}"

  rsync -ac $CANDALF_ROOT/lib/cast.sh $CANDALF_REMOTE_ROOT/lib/cast.sh

  rsync -Rac $SPELL_BOOK \
    $(grep -E "^cast.*\.sh" $SPELL_BOOK | rev | awk '{print $1}' | rev) \
    $CANDALF_REMOTE_ROOT

  bash -c "export CANDALF_ROOT=$CANDALF_REMOTE_ROOT; \
    export VERBOSE=$VERBOSE; \
    $CANDALF_REMOTE_ROOT/$SPELL_BOOK 2>&1" | tee -a /var/log/candalf.log
}

bootstrap() {
  $CANDALF_ROOT/lib/bootstrap.sh
}

