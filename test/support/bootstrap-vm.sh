#!/usr/bin/env sh

test "$VERBOSE" && set -x
set -Eeuo pipefail

compat_sed() {
  SUBSITUTION_CMD="$1"
  EDITED_FILE="$2"

  sed -i "$SUBSITUTION_CMD" "$EDITED_FILE" 2>/dev/null || \
    sed -i "" -e "$SUBSITUTION_CMD" "$EDITED_FILE"
}

compat_useradd() {
  USER="$1"
  (which "useradd" >/dev/null && useradd -m "$USER") || \
    (which "adduser" >/dev/null && adduser -D "$USER") || \
    (which "pw" >/dev/null && pw useradd -mn "$USER") || \
    (echo "No useradd binaries detected" && exit 1)
}

cp -R /home/vagrant/.ssh /root
compat_sed "s/#PermitRootLogin.*/PermitRootLogin yes/" "/etc/ssh/sshd_config"
compat_sed "s/#UseDNS.*/UseDNS no/" "/etc/ssh/sshd_config"
compat_sed "s/root:!/root:\*/g" /etc/shadow
service sshd reload
compat_useradd "john"
which "apk" >/dev/null && apk add shadow
