#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

whoami > ~/me
cat ~/me
