all: test

ALPINE_LINUX = alpine315
UBUNTU_LINUX = ubuntu2110
FREEBSD = freebsd13
ARCH_LINUX = arch
CENTOS = centos8
FEDORA_LINUX = fedora35

TEST = test/test-example.sh

shellcheck:
	shellcheck -V && shellcheck `find . -name "*.sh" | grep -v test-book`

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

test-one:
	VAGRANT_BOX=generic/${ALPINE_LINUX} ${TEST}
	VAGRANT_BOX=generic/${UBUNTU_LINUX} ${TEST}
	VAGRANT_BOX=generic/${FREEBSD} ${TEST}
	VAGRANT_BOX=generic/${ARCH_LINUX} ${TEST}
	VAGRANT_BOX=generic/${CENTOS} ${TEST}
	VAGRANT_BOX=generic/${FEDORA_LINUX} ${TEST}

test: shellcheck test-alpine test-ubuntu test-freebsd test-arch test-centos test-fedora

.PHONY: all shellcheck test-alpine test-ubuntu test-freebsd test-arch test-centos test-fedora test-one test
