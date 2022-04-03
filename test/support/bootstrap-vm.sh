#!/usr/bin/env sh

test "$VERBOSE" && set -x
set -eu

compat_sed() {
  SUBSITUTION_CMD="$1"
  EDITED_FILE="$2"

  sed -i "$SUBSITUTION_CMD" "$EDITED_FILE" 2>/dev/null || \
    sed -i "" -e "$SUBSITUTION_CMD" "$EDITED_FILE"
}

compat_useradd() {
  NEW_USER="$1"
  (command -v useradd > /dev/null && useradd -m "$NEW_USER") || \
    (command -v pw > /dev/null && pw useradd -mn "$NEW_USER") || \
    (command -v adduser && adduser -D "$NEW_USER") || \
    (echo "No useradd binaries detected" && exit 1)
}

cp -R /home/vagrant/.ssh /root
compat_sed "s/#PermitRootLogin.*/PermitRootLogin yes/" "/etc/ssh/sshd_config"
compat_sed "s/#UseDNS.*/UseDNS no/" "/etc/ssh/sshd_config"
test -f /etc/shadow && compat_sed "s/root:!/root:\*/g" /etc/shadow
(command -v service > /dev/null && service sshd reload) || \
  (command -v systemctl > /dev/null && systemctl reload sshd)
compat_useradd "john"

(command -v apk > /dev/null && apk add shadow) || true
