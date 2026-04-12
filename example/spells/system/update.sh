#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

apt update -y
touch ~/candalf-example-update
