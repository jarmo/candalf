#!/usr/bin/env bash

set -Eeuo pipefail

TEST_DIR="${TEST_DIR:?"TEST_DIR is required!"}"
KEEP_VM="${KEEP_VM:-""}"
SNAPSHOT_NAME="pristine"

vm_prepare() {
  # Enable Vagrant on Windows WSL too
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
  export PATH="/mnt/c/Program Files/Oracle/VirtualBox:$PATH"

  vm_destroy
  vm_start
  vm_save
}

vm_start() {
  vagrant up
}

vm_destroy() {
  [[ "$KEEP_VM" = 1 ]] || vagrant destroy --force
}

vm_save() {
  vagrant snapshot save --force "$SNAPSHOT_NAME"
}

vm_restore() {
  vm_is_running && \
    ([[ "$KEEP_VM" = 1 ]] || vagrant snapshot restore --no-provision "$SNAPSHOT_NAME")
}

vm_exec() {
  CMD="${1:?"CMD is required!"}"
  ssh -q -F "$TEST_DIR/support/ssh/config" candalf-test "${CMD}"
}

vm_is_running() {
  nc -z candalf-test 2222
}

