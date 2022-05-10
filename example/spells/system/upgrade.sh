#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

apt update -y
apt upgrade -y

touch ~/upgrade-done
