#!/usr/bin/env bash

test  && set -x
set -Eeo pipefail

date +"%Y-%m-%d" > ~/today
cat ~/today
