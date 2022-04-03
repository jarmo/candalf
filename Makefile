all: test

shellcheck:
	shellcheck -V && shellcheck `find . -name "*.sh"`

test-alpine:
	VAGRANT_BOX=generic/alpine315 test/test-all.sh

test-ubuntu:
	VAGRANT_BOX=generic/ubuntu2110 test/test-all.sh

test-freebsd:
	VAGRANT_BOX=generic/freebsd13 test/test-all.sh

test: shellcheck test-alpine test-ubuntu test-freebsd

.PHONY: all shellcheck test-alpine test-ubuntu test-freebsd test
