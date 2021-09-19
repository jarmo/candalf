#!/usr/bin/env bash

candalfEnv() {
  candalfEnvVars=(CANDALF_ENV_VAR_PLACEHOLDER=1)

  while IFS= read -d "" -r var; do
    [[ "$var" == CANDALF_* ]] && candalfEnvVars+=("$var")
  done < <(env -0)

  declare -p candalfEnvVars
}
