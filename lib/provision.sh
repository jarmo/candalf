#!/usr/bin/env sh

VERBOSE="${VERBOSE:-""}"

set -e
if [ "$VERBOSE" != "" ]; then set -x; fi

PROVISIONER_REMOTE_ROOT='~/.provisioner'
SSH_OUTPUT_FLAG=$(test "$VERBOSE" != "" && echo "-v" || echo "-q")

provision() {
  SERVER_PROVISION_FILE="${1:?"server provision file not set!"}"
  SERVER_HOSTNAME=$(basename $SERVER_PROVISION_FILE | rev | cut -d "." -f2- | rev)
  rsync $SSH_OUTPUT_FLAG -ac $PROVISIONER_ROOT/lib/apply.sh -e "ssh -q" $SERVER_HOSTNAME:$PROVISIONER_REMOTE_ROOT/lib/apply.sh
  rsync $SSH_OUTPUT_FLAG -Rac $SERVER_PROVISION_FILE $(grep -E "^apply .*\.sh" $SERVER_PROVISION_FILE | cut -d " " -f 2) -e "ssh $SSH_OUTPUT_FLAG" $SERVER_HOSTNAME:$PROVISIONER_REMOTE_ROOT
  ssh $SSH_OUTPUT_FLAG -tt "$SERVER_HOSTNAME" "bash -c \"export SERVER_HOSTNAME=$SERVER_HOSTNAME; export PROVISIONER_ROOT=$PROVISIONER_REMOTE_ROOT; export VERBOSE=$VERBOSE; $PROVISIONER_REMOTE_ROOT/$SERVER_PROVISION_FILE 2>&1 | tee -a /var/log/provisioner.log\"" 
}

bootstrap() {
  SERVER_PROVISION_FILE="${1:?"server provision file not set!"}"
  SERVER_HOSTNAME=$(basename $SERVER_PROVISION_FILE | rev | cut -d "." -f2- | rev)

  HOSTNAME=$(hostname -s 2>/dev/null || hostname -f)
  USERNAME=$(id -un)
  SSH_KEY_LABEL=$USERNAME@$HOSTNAME
  SSH_KEY_PATH=~/.ssh/$SERVER_HOSTNAME

  if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Trying to login to $SERVER_HOSTNAME by using root password"
    ssh $SSH_OUTPUT_FLAG -tt -o PubkeyAuthentication=no -o PasswordAuthentication=yes -o IdentitiesOnly=yes -o PreferredAuthentications=password root@"$SERVER_HOSTNAME" 'echo "Logged successfully into $HOST for the first time, creating key"'
    ssh-keygen -a 100 -t ed25519 -f "$SSH_KEY_PATH" -C "$SSH_KEY_LABEL"
  fi

  SSH_LOGIN_COMMAND="ssh $SSH_OUTPUT_FLAG -tt -o PubkeyAuthentication=yes -o PasswordAuthentication=no -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -i '$SSH_KEY_PATH' root@'$SERVER_HOSTNAME' 'test 1 -eq 1'"
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

  if ! nc -z "$SERVER_HOSTNAME" $SSH_SERVER_PORT; then
    cat $PROVISIONER_ROOT/lib/sshd-remote.sh | ssh $SSH_OUTPUT_FLAG -o PubkeyAuthentication=yes -o PasswordAuthentication=no -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -i "$SSH_KEY_PATH" root@"$SERVER_HOSTNAME" "export SSH_SERVER_PORT=$SSH_SERVER_PORT 2>/dev/null || setenv SSH_SERVER_PORT $SSH_SERVER_PORT; sh -"
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

  cat $PROVISIONER_ROOT/lib/bootstrap-remote.sh | ssh $SSH_OUTPUT_FLAG "$SERVER_HOSTNAME" "export PROVISIONER_ROOT=$PROVISIONER_REMOTE_ROOT 2>/dev/null || setenv PROVISIONER_ROOT $PROVISIONER_REMOTE_ROOT; sh -"
}

