#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

date +"%Y-%m-%d" > ~/today
cat ~/today
