all: test

ALPINE_LINUX = alpine315
UBUNTU_LINUX = ubuntu2110
FREEBSD = freebsd13
ARCH_LINUX = arch
CENTOS = centos8
FEDORA_LINUX = fedora35

shellcheck:
	shellcheck -V && shellcheck `find . -name "*.sh"`

test-alpine:
	VAGRANT_BOX=generic/${ALPINE_LINUX} test/test-all.sh

test-ubuntu:
	VAGRANT_BOX=generic/${UBUNTU_LINUX} test/test-all.sh

test-freebsd:
	VAGRANT_BOX=generic/${FREEBSD} test/test-all.sh

test-arch:
	VAGRANT_BOX=generic/${ARCH_LINUX} test/test-all.sh

test-centos:
	VAGRANT_BOX=generic/${CENTOS} test/test-all.sh

test-fedora:
	VAGRANT_BOX=generic/${FEDORA_LINUX} test/test-all.sh

test-example:
	VAGRANT_BOX=generic/${ALPINE_LINUX} test/test-example.sh
	VAGRANT_BOX=generic/${UBUNTU_LINUX} test/test-example.sh
	VAGRANT_BOX=generic/${FREEBSD} test/test-example.sh
	VAGRANT_BOX=generic/${ARCH_LINUX} test/test-example.sh
	VAGRANT_BOX=generic/${CENTOS} test/test-example.sh
	VAGRANT_BOX=generic/${FEDORA_LINUX} test/test-example.sh

test: shellcheck test-alpine test-ubuntu test-freebsd test-arch test-centos test-fedora test-example

.PHONY: all shellcheck test-alpine test-ubuntu test-freebsd test-arch test-centos test-fedora test-example test
