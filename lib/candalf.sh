#!/usr/bin/env bash

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -Eeuo pipefail

# shellcheck disable=SC2016
CANDALF_REMOTE_ROOT='$HOME/.candalf'
SSH_OUTPUT_FLAG=$(test "$VERBOSE" && echo "-q" || echo "-v")

. "$CANDALF_ROOT"/lib/candalf-env.sh
eval "$(candalfEnv)"

candalf() {
  CANDALF_SERVER="${1:?"CANDALF_SERVER not set!"}"
  SPELL_BOOK="${2:?"SPELL_BOOK not set!"}"
  SPELL_BOOK_PATH="$(realpath "$SPELL_BOOK")"
  SPELL_BOOK_DIR="$(dirname "$SPELL_BOOK_PATH")"
  SPELL_BOOK_BASENAME="$(basename "$SPELL_BOOK")"
  SPELL_BOOK_BASENAME_WITHOUT_EXT="$(basename "$SPELL_BOOK_BASENAME" .sh)"
  CANDALF_SPELLS_ROOT="$CANDALF_REMOTE_ROOT/$SPELL_BOOK_BASENAME_WITHOUT_EXT"

  rsync "$SSH_OUTPUT_FLAG" -ac "$CANDALF_ROOT"/lib/cast.sh "$CANDALF_ROOT"/lib/candalf-env.sh -e "ssh -q" \
    "$CANDALF_SERVER":$CANDALF_REMOTE_ROOT/lib

  cd "$SPELL_BOOK_DIR"
  rsync "$SSH_OUTPUT_FLAG" --exclude ".**" -Rac "." \
    -e "ssh $SSH_OUTPUT_FLAG" "$CANDALF_SERVER":"$CANDALF_SPELLS_ROOT"
  cd - >/dev/null

  # shellcheck disable=SC2154,SC2029
  ssh "$SSH_OUTPUT_FLAG" -tt "$CANDALF_SERVER" \
    env "${candalfEnvVars[@]-}" CANDALF_ROOT="$CANDALF_REMOTE_ROOT" CANDALF_SPELLS_ROOT="$CANDALF_SPELLS_ROOT" CANDALF_DRY_RUN="$CANDALF_DRY_RUN" VERBOSE="$VERBOSE" \
      "bash -c '$CANDALF_SPELLS_ROOT/$SPELL_BOOK_BASENAME 2>&1' | tee -a /var/log/candalf.log"
}

bootstrap() {
  CANDALF_SERVER="${1:?"CANDALF_SERVER not set!"}"

  HOSTNAME=$(hostname -s 2>/dev/null || hostname -f)
  USERNAME=$(id -un)
  SSH_KEY_LABEL=$USERNAME@$HOSTNAME
  SSH_KEY_PATH=~/.ssh/$CANDALF_SERVER

  if [[ ! -f "$SSH_KEY_PATH" ]] && grep -q "Host $CANDALF_SERVER" ~/.ssh/config; then
    SSH_KEY_PATH="$(ssh -G "$CANDALF_SERVER" | grep "identityfile" | cut -d " " -f2)"
    SSH_KEY_PATH=${SSH_KEY_PATH/#\~/$HOME}
  fi

  if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Trying to login to $CANDALF_SERVER by using root password"

    ssh "$SSH_OUTPUT_FLAG" -tt \
      -o PubkeyAuthentication=no \
      -o PasswordAuthentication=yes \
      -o IdentitiesOnly=yes \
      -o PreferredAuthentications=password \
      root@"$CANDALF_SERVER" \
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
    root@'$CANDALF_SERVER' 'true'"

  if ! eval "$SSH_LOGIN_COMMAND" || false; then
    echo "Failed to login using SSH key, trying to copy key to the $CANDALF_SERVER"
    ssh-copy-id -o IdentitiesOnly=yes -i "$SSH_KEY_PATH" root@"$CANDALF_SERVER"
    eval "$SSH_LOGIN_COMMAND"
    echo "From now on use SSH key $SSH_KEY_PATH for logging into root@$CANDALF_SERVER"
  fi

  if ! grep --quiet "Host $CANDALF_SERVER" ~/.ssh/config; then
    SSH_SERVER_PORT=$(shuf -i 13337-65535 -n 1)
  else
    SSH_SERVER_PORT=$(grep -A 10 "Host $CANDALF_SERVER" ~/.ssh/config | grep "Port" | head -1 | cut -d " " -f4)
  fi    

  if ! nc -z "$CANDALF_SERVER" "$SSH_SERVER_PORT"; then
    # shellcheck disable=SC2029
    ssh "$SSH_OUTPUT_FLAG" \
      -o PubkeyAuthentication=yes \
      -o PasswordAuthentication=no \
      -o IdentitiesOnly=yes \
      -o PreferredAuthentications=publickey \
      -i "$SSH_KEY_PATH" \
      root@"$CANDALF_SERVER" \
      "env SSH_SERVER_PORT=$SSH_SERVER_PORT sh" < "$CANDALF_ROOT"/lib/sshd.sh
  fi

  if ! grep --quiet "Host $CANDALF_SERVER" ~/.ssh/config; then
    cat << EOF >> ~/.ssh/config

Host $CANDALF_SERVER
  Hostname $CANDALF_SERVER
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
  ssh "$SSH_OUTPUT_FLAG" "$CANDALF_SERVER" \
    env CANDALF_ROOT="$CANDALF_REMOTE_ROOT" sh < "$CANDALF_ROOT"/lib/bootstrap.sh
}

kill_ssh_agent() {
  test "$SSH_AGENT_PID" && kill "$SSH_AGENT_PID"
}
