#!/usr/bin/env bash

candalfEnv() {
  candalfEnvVars=()

  while IFS= read -d "" -r var; do
    [[ "$var" == CANDALF_* ]] && candalfEnvVars+=("$var")
  done < <(env -0)

  declare -p candalfEnvVars
}
