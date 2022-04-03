all: test

shellcheck:
	shellcheck -V && shellcheck `find . -name "*.sh"`

test-alpine:
	VAGRANT_BOX=generic/alpine315 test/test-all.sh

test-ubuntu:
	VAGRANT_BOX=generic/ubuntu2110 test/test-all.sh

test-freebsd:
	VAGRANT_BOX=generic/freebsd13 test/test-all.sh

test-arch:
	VAGRANT_BOX=generic/arch test/test-all.sh

test-example:
	VAGRANT_BOX=generic/alpine312 test/test-example.sh
	VAGRANT_BOX=generic/ubuntu2110 test/test-example.sh
	VAGRANT_BOX=generic/freebsd13 test/test-example.sh
	VAGRANT_BOX=generic/arch test/test-example.sh

test: shellcheck test-alpine test-ubuntu test-freebsd test-arch test-example

.PHONY: all shellcheck test-alpine test-ubuntu test-freebsd test-arch test
