#!/usr/bin/env sh

set -Eeu
VERBOSE="${VERBOSE:-""}"
if [ "$VERBOSE" != "" ]; then set -x; fi

mkdir -p $HOME/.candalf/lib
mkdir -p /var/log
touch /var/log/candalf.log
chmod 640 /var/log/candalf.log
which rsync >/dev/null || apt install -y rsync 2>/dev/null || pkg install -y rsync
which bash >/dev/null || apt install -y bash 2>/dev/null || pkg install -y bash