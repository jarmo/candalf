#!/usr/bin/env sh

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -eu

compat_which() {
  BINARY="$1"

  which "$BINARY" 2>/dev/null || \
    whereis "$BINARY" 2>/dev/null | awk '{print $2}'
}

install() {
  PACKAGE=$1
  test "$(compat_which "$PACKAGE")" || \
    (test "$(compat_which apt)" && apt install -y "$PACKAGE") || \
    (test "$(compat_which pkg)" && pkg install -y "$PACKAGE") || \
    (test "$(compat_which apk)" && apk add "$PACKAGE") || \
    (test "$(compat_which pacman)" && pacman -S --noconfirm "$PACKAGE") || \
    (echo "No supported package manager found, cannot continue!" && exit 1)
}

mkdir -p "$HOME"/.candalf/lib
mkdir -p /var/log
touch /var/log/candalf.log
chmod 640 /var/log/candalf.log
install rsync
install bash
install sudo
