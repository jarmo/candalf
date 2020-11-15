#!/usr/bin/env sh

set -e

mkdir -p $PROVISIONER_ROOT/lib
mkdir -p /var/log
touch /var/log/provisioner.log
chmod 640 /var/log/provisioner.log
which rsync >/dev/null || apt install -y rsync 2>/dev/null || pkg install -y rsync
which bash >/dev/null || apt install -y bash 2>/dev/null || pkg install -y bash
