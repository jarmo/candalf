#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

whoami > ~/candalf-example-me
cat ~/candalf-example-me
