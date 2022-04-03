all: test

shellcheck:
	shellcheck -V && shellcheck `find . -name "*.sh"`

test-ubuntu:
	VAGRANT_BOX=generic/ubuntu2110 test/test-all.sh

test-freebsd:
	VAGRANT_BOX=generic/freebsd13 test/test-all.sh

test: shellcheck test-ubuntu test-freebsd

.PHONY: all shellcheck test-ubuntu test-freebsd test
