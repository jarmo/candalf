#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

date +"%Y-%m-%d" > ~/candalf-example-today
cat ~/candalf-example-today
