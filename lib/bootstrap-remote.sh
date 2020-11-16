#!/usr/bin/env sh

set -e

mkdir -p $CANDALF_ROOT/lib
mkdir -p /var/log
touch /var/log/candalf.log
chmod 640 /var/log/candalf.log
which rsync >/dev/null || apt install -y rsync 2>/dev/null || pkg install -y rsync
which bash >/dev/null || apt install -y bash 2>/dev/null || pkg install -y bash
