#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

CANDALF_REMOTE_ROOT="$HOME/.candalf"

candalf() {
  SPELL_BOOK="${2:?"SPELL_BOOK not set!"}"
  SPELL_BOOK_PATH="$(realpath "$SPELL_BOOK")"
  SPELL_BOOK_DIR="$(dirname "$SPELL_BOOK_PATH")"
  SPELL_BOOK_BASENAME="$(basename "$SPELL_BOOK")"
  SPELL_BOOK_BASENAME_WITHOUT_EXT="$(basename "$SPELL_BOOK_BASENAME" .sh)"
  CANDALF_SPELLS_ROOT="$CANDALF_REMOTE_ROOT/$SPELL_BOOK_BASENAME_WITHOUT_EXT"

  rsync -ac "$CANDALF_ROOT"/lib/cast.sh "$CANDALF_ROOT"/lib/candalf-env.sh "$CANDALF_ROOT"/lib/colors.sh "$CANDALF_REMOTE_ROOT"/lib

  cd "$SPELL_BOOK_DIR"
  rsync --exclude ".**" -Rac "." "$CANDALF_SPELLS_ROOT"
  cd - >/dev/null

  # shellcheck disable=SC2154
  env CANDALF_ROOT="$CANDALF_REMOTE_ROOT" \
    CANDALF_SPELLS_ROOT="$CANDALF_SPELLS_ROOT" \
    HISTFILE=/dev/null \
    bash -c "$(printf "%q" "$CANDALF_SPELLS_ROOT/$SPELL_BOOK_BASENAME")" 2>&1 | tee -a /var/log/candalf.log
}

bootstrap() {
  if [[ "$USER" != "root" ]]; then
    echo "candalf needs to be executed with root user like this:
sudo -H candalf..."
    exit 1
  fi

  "$CANDALF_ROOT"/lib/bootstrap.sh
}

