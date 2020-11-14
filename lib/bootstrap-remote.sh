#!/usr/bin/env sh

set -e

mkdir -p $PROVISIONER_REMOTE_ROOT/lib
mkdir -p /var/log
touch /var/log/provisioner.log
chmod 640 /var/log/provisioner.log
which rsync >/dev/null || apt install -y rsync || pkg install -y rsync
which bash >/dev/null || apt install -y bash || pkg install -y bash
