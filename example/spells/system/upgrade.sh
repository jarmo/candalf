#!/usr/bin/env bash

test  && set -x
set -Eeo pipefail

apt update -y
apt upgrade -y
