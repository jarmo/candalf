#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

. "${CANDALF_ROOT:="."}"/lib/cast.sh

# Following spell is never cast
CAST_NEVER=1 cast spells/system/update.sh

# Following spell is always cast as root user
CAST_ALWAYS=1 cast spells/today.sh 

# Following spell is cast as root user
cast spells/whoami.sh

# Following spell is cast as non-privileged john user
cast_as john spells/whoami.sh

