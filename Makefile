all: test

ALPINE_LINUX := alpine319
UBUNTU_LINUX := ubuntu2204
FREEBSD      := freebsd14
ARCH_LINUX   := arch
CENTOS       := centos9s
FEDORA_LINUX := fedora35

# Use TEST when supplied; otherwise run the complete suite.
TEST_SCRIPT := $(if $(strip $(TEST)),$(TEST),test/test-all.sh)

TEST_BOXES := \
	test-alpine \
	test-ubuntu \
	test-freebsd \
	test-arch \
	test-centos \
	test-fedora

shellcheck:
	shellcheck -V
	shellcheck $$(find . -name '*.sh' | grep -v test-book)

test-alpine: VAGRANT_BOX := generic/$(ALPINE_LINUX)
test-ubuntu: VAGRANT_BOX := generic/$(UBUNTU_LINUX)
test-freebsd: VAGRANT_BOX := generic/$(FREEBSD)
test-arch: VAGRANT_BOX := generic/$(ARCH_LINUX)
test-centos: VAGRANT_BOX := generic/$(CENTOS)
test-fedora: VAGRANT_BOX := generic/$(FEDORA_LINUX)

$(TEST_BOXES):
	VAGRANT_BOX=$(VAGRANT_BOX) $(TEST_SCRIPT)

test-one: $(TEST_BOXES)

test: shellcheck $(TEST_BOXES)

.PHONY: all shellcheck test test-one $(TEST_BOXES)
