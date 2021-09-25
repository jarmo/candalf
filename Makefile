all: test

test:
	shellcheck -V && shellcheck candalf.sh **/*.sh

.PHONY: all test
