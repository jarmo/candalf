#!/usr/bin/env sh

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -eu

install() {
  PACKAGE=$1
  command -v "$PACKAGE" >/dev/null || \
    (command -v apt >/dev/null && apt install -y "$PACKAGE") || \
    (command -v pkg >/dev/null && pkg install -y "$PACKAGE") || \
    (command -v apk >/dev/null && apk add "$PACKAGE") || \
    (command -v pacman >/dev/null && pacman -S --noconfirm "$PACKAGE") || \
    (command -v yum >/dev/null && yum install -y "$PACKAGE") || \
    (echo "No supported package manager found, cannot continue!" && exit 1)
}

mkdir -p "$HOME"/.candalf/lib
mkdir -p /var/log
touch /var/log/candalf.log
chmod 640 /var/log/candalf.log
install rsync
install bash
install sudo
