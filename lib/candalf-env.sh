#!/usr/bin/env bash

candalfEnv() {
  candalfEnvVars=(CANDALF_ENV_VAR_PLACEHOLDER=1)

  while IFS= read -r -d '' var; do
    [[ "$var" == CANDALF_* ]] && candalfEnvVars+=("$var")
  done < <( [[ -f /proc/self/environ ]] && cat /proc/self/environ || env -0)

  declare -p candalfEnvVars
}
