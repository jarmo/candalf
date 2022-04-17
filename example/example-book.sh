#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

. "${CANDALF_ROOT:="."}"/lib/cast.sh

CAST_NEVER=1 cast spells/system/upgrade.sh
CAST_ALWAYS=1 cast spells/today.sh 

cast spells/whoami.sh
cast_as john spells/john/whoami.sh

