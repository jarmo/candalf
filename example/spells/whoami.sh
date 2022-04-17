#!/usr/bin/env bash

test  && set -x
set -Eeo pipefail

whoami > ~/me
cat ~/me
