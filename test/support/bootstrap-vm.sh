#!/usr/bin/env sh

test "$VERBOSE" && set -x
set -eu

compat_sed() {
  SUBSITUTION_CMD="$1"
  EDITED_FILE="$2"

  sed -i "$SUBSITUTION_CMD" "$EDITED_FILE" 2>/dev/null || \
    sed -i "" -e "$SUBSITUTION_CMD" "$EDITED_FILE"
}

compat_which() {
  BINARY="$1"

  which "$BINARY" 2>/dev/null || \
    whereis "$BINARY" | awk '{print $2}'
}

compat_useradd() {
  USER="$1"
  (test "$(compat_which "useradd")" && useradd -m "$USER") || \
    (test "$(compat_which "adduser")" && adduser -D "$USER") || \
    (test "$(compat_which "pw")" && pw useradd -mn "$USER") || \
    (echo "No useradd binaries detected" && exit 1)
}

cp -R /home/vagrant/.ssh /root
compat_sed "s/#PermitRootLogin.*/PermitRootLogin yes/" "/etc/ssh/sshd_config"
compat_sed "s/#UseDNS.*/UseDNS no/" "/etc/ssh/sshd_config"
test -f /etc/shadow && compat_sed "s/root:!/root:\*/g" /etc/shadow
(test "$(compat_which "service")" && service sshd reload) || \
  (test "$(compat_which "systemctl")" && systemctl reload sshd)
compat_useradd "john"

(test "$(compat_which "apk")" && apk add shadow) || true
