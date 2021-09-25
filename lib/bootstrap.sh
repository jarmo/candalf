#!/usr/bin/env sh

VERBOSE="${VERBOSE:-""}"
test "$VERBOSE" && set -x
set -eu

install() {
  PACKAGE=$1
  which "$PACKAGE" >/dev/null || \
    (which apt >/dev/null && apt install -y "$PACKAGE") || \
    (which pkg >/dev/null && pkg install -y "$PACKAGE") || \
    (echo "No supported package manager found, cannot continue!" && exit 1)
}

mkdir -p "$HOME"/.candalf/lib
mkdir -p /var/log
touch /var/log/candalf.log
chmod 640 /var/log/candalf.log
install rsync
install bash
install sudo
