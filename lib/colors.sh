#!/usr/bin/env bash

CANDALF_NO_COLOR="${CANDALF_NO_COLOR:-""}"

export COLOR_RED=""
export COLOR_RED_BG=""
export COLOR_GREEN=""
export COLOR_GREEN_BG=""
export COLOR_YELLOW=""
export COLOR_YELLOW_BG=""
export COLOR_MAGENTA=""
export COLOR_GREY=""
export COLOR_END=""

if [[ "$CANDALF_NO_COLOR" == "" ]]; then
  COLOR_RED='\033[0;31m'
  COLOR_RED_BG='\033[0;41m'
  COLOR_GREEN='\033[0;32m'
  COLOR_GREEN_BG='\033[0;42m'
  COLOR_YELLOW='\033[0;33m'
  COLOR_YELLOW_BG='\033[0;43m'
  COLOR_MAGENTA='\033[0;35m'
  COLOR_GREY='\033[0;90m'
  COLOR_END='\033[0;0m'
fi
