all: test

test:
	shellcheck -s bash candalf.sh **/*.sh

.PHONY: all test
