#!/usr/bin/env sh

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -eu

compat_sed() {
  SUBSTITUTION_CMD="$1"
  EDITED_FILE="$2"

  sed -i "$SUBSTITUTION_CMD" "$EDITED_FILE" 2>/dev/null || \
    sed -i "" -e "$SUBSTITUTION_CMD" "$EDITED_FILE"
}

echo "Disable password login to SSH server"
compat_sed "s/.*PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config 2>/dev/null

echo "Disable passing client locale environment variables"
compat_sed "s/.*AcceptEnv LANG LC_/#AcceptEnv LANG LC_/" /etc/ssh/sshd_config

echo "Change SSH server port to $SSH_SERVER_PORT"
compat_sed "s/^#Port 22/Port $SSH_SERVER_PORT/" /etc/ssh/sshd_config

if command -v systemctl >/dev/null && [ -f /etc/systemd/system/sockets.target.wants/ssh.socket ]; then
  compat_sed "s/.*ListenStream=22/#ListenStream=22/" /etc/systemd/system/sockets.target.wants/ssh.socket
  systemctl daemon-reload
  systemctl enable ssh
fi

echo "Restart SSH server"
service ssh restart 2>/dev/null || service sshd restart
