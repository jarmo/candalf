#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

# shellcheck disable=SC2016
CANDALF_REMOTE_ROOT='$HOME/.candalf'
SSH_OUTPUT_FLAG=$([ -z "$VERBOSE" ] && echo "-q" || echo "-v")

. "$CANDALF_ROOT"/lib/candalf-env.sh
eval "$(candalfEnv)"

candalf() {
  SPELL_BOOK="${1:?"SPELL_BOOK not set!"}"
  SERVER_HOSTNAME=$(basename "$SPELL_BOOK" | rev | cut -d "." -f2- | rev)

  rsync "$SSH_OUTPUT_FLAG" -ac "$CANDALF_ROOT"/lib/cast.sh "$CANDALF_ROOT"/lib/candalf-env.sh -e "ssh -q" \
    "$SERVER_HOSTNAME":$CANDALF_REMOTE_ROOT/lib

  # shellcheck disable=SC2046
  rsync "$SSH_OUTPUT_FLAG" --exclude ".**" -Rac "." \
    -e "ssh $SSH_OUTPUT_FLAG" "$SERVER_HOSTNAME":$CANDALF_REMOTE_ROOT

  # shellcheck disable=SC2154,SC2029
  ssh "$SSH_OUTPUT_FLAG" -tt "$SERVER_HOSTNAME" \
    env CANDALF_ROOT="$CANDALF_REMOTE_ROOT" VERBOSE="$VERBOSE" "${candalfEnvVars[@]-}" "bash -c '$CANDALF_REMOTE_ROOT/$SPELL_BOOK 2>&1' | tee -a /var/log/candalf.log"
}

bootstrap() {
  SPELL_BOOK="${1:?"SPELL_BOOK not set!"}"
  SERVER_HOSTNAME=$(basename "$SPELL_BOOK" | rev | cut -d "." -f2- | rev)

  HOSTNAME=$(hostname -s 2>/dev/null || hostname -f)
  USERNAME=$(id -un)
  SSH_KEY_LABEL=$USERNAME@$HOSTNAME
  SSH_KEY_PATH=~/.ssh/$SERVER_HOSTNAME

  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Trying to login to $SERVER_HOSTNAME by using root password"

    ssh "$SSH_OUTPUT_FLAG" -tt \
      -o PubkeyAuthentication=no \
      -o PasswordAuthentication=yes \
      -o IdentitiesOnly=yes \
      -o PreferredAuthentications=password \
      root@"$SERVER_HOSTNAME" \
      'echo "Logged successfully into $HOST for the first time, creating key"'

    ssh-keygen -a 100 -t ed25519 -f "$SSH_KEY_PATH" -C "$SSH_KEY_LABEL"
  fi

  trap kill_ssh_agent ERR
  trap kill_ssh_agent EXIT
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add -t 300 "$SSH_KEY_PATH" 2>/dev/null

  SSH_LOGIN_COMMAND="ssh $SSH_OUTPUT_FLAG -tt \
    -o PubkeyAuthentication=yes \
    -o PasswordAuthentication=no \
    -o IdentitiesOnly=yes \
    -o PreferredAuthentications=publickey \
    -i '$SSH_KEY_PATH' \
    root@'$SERVER_HOSTNAME' 'true'"

  if ! eval "$SSH_LOGIN_COMMAND" || false; then
    echo "Failed to login using SSH key, trying to copy key to the $SERVER_HOSTNAME"
    ssh-copy-id -o IdentitiesOnly=yes -i "$SSH_KEY_PATH" root@"$SERVER_HOSTNAME"
    eval "$SSH_LOGIN_COMMAND"
    echo "From now on use SSH key $SSH_KEY_PATH for logging into root@$SERVER_HOSTNAME"
  fi

  if ! grep --quiet "Host $SERVER_HOSTNAME" ~/.ssh/config; then
    SSH_SERVER_PORT=$(shuf -i 13337-65535 -n 1)
  else
    SSH_SERVER_PORT=$(grep -A 10 "Host $SERVER_HOSTNAME" ~/.ssh/config | grep "Port" | head -1 | cut -d " " -f4)
  fi    

  if ! nc -z "$SERVER_HOSTNAME" "$SSH_SERVER_PORT"; then
    # shellcheck disable=SC2029
    ssh "$SSH_OUTPUT_FLAG" \
      -o PubkeyAuthentication=yes \
      -o PasswordAuthentication=no \
      -o IdentitiesOnly=yes \
      -o PreferredAuthentications=publickey \
      -i "$SSH_KEY_PATH" \
      root@"$SERVER_HOSTNAME" \
      "env SSH_SERVER_PORT=$SSH_SERVER_PORT sh" < "$CANDALF_ROOT"/lib/sshd.sh
  fi

  if ! grep --quiet "Host $SERVER_HOSTNAME" ~/.ssh/config; then
    cat << EOF >> ~/.ssh/config

Host $SERVER_HOSTNAME
  Hostname $SERVER_HOSTNAME
  Port $SSH_SERVER_PORT
  User root
  IdentityFile $SSH_KEY_PATH
  IdentitiesOnly yes
  PasswordAuthentication no
  PubkeyAuthentication yes
  PreferredAuthentications publickey
EOF
  fi

  # shellcheck disable=SC2029
  ssh "$SSH_OUTPUT_FLAG" "$SERVER_HOSTNAME" \
    "env CANDALF_ROOT=$CANDALF_REMOTE_ROOT sh" < "$CANDALF_ROOT"/lib/bootstrap.sh
}

kill_ssh_agent() {
  test "$SSH_AGENT_PID" && kill "$SSH_AGENT_PID"
}
