#!/usr/bin/env bash

candalfEnv() {
  candalfEnvVars=(CANDALF_ENV_VAR_PLACEHOLDER=1)

  while IFS= read -r -d '' var; do
    [[ "$var" == CANDALF_* ]] && candalfEnvVars+=("$var")
  done </proc/self/environ

  declare -p candalfEnvVars
}
