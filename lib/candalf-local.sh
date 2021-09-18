#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

CANDALF_REMOTE_ROOT=$HOME/.candalf

. "$CANDALF_ROOT"/lib/candalf-env.sh
eval "$(candalfEnv)"

candalf() {
  SPELL_BOOK="${2:?"SPELL_BOOK not set!"}"

  rsync -ac "$CANDALF_ROOT"/lib/cast.sh "$CANDALF_REMOTE_ROOT"/lib/cast.sh

  rsync -Rac "$SPELL_BOOK" \
    "$(grep -E "^cast.*\.sh" "$SPELL_BOOK" | rev | awk '{print $1}' | rev)" \
    "$CANDALF_REMOTE_ROOT"

    # shellcheck disable=SC2154
    env "${candalfEnvVars[@]-}" bash -c "CANDALF_ROOT=$CANDALF_REMOTE_ROOT VERBOSE=$VERBOSE \
      $CANDALF_REMOTE_ROOT/$SPELL_BOOK 2>&1" | tee -a /var/log/candalf.log
}

bootstrap() {
  "$CANDALF_ROOT"/lib/bootstrap.sh
}

