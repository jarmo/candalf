#!/bin/bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

. ./lib/local.sh

provision "$1"
