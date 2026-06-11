all: test

ALPINE_LINUX := generic/alpine319
UBUNTU_LINUX := cloud-image/ubuntu-26.04
FREEBSD      := generic/freebsd14
ARCH_LINUX   := generic/arch
CENTOS       := generic/centos9s
FEDORA_LINUX := generic/fedora35

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

test-alpine: VAGRANT_BOX := $(ALPINE_LINUX)
test-ubuntu: VAGRANT_BOX := $(UBUNTU_LINUX)
test-freebsd: VAGRANT_BOX := $(FREEBSD)
test-arch: VAGRANT_BOX := $(ARCH_LINUX)
test-centos: VAGRANT_BOX := $(CENTOS)
test-fedora: VAGRANT_BOX := $(FEDORA_LINUX)

$(TEST_BOXES):
	VAGRANT_BOX=$(VAGRANT_BOX) $(TEST_SCRIPT)

test-one: $(TEST_BOXES)

test: shellcheck $(TEST_BOXES)

.PHONY: all shellcheck test test-one $(TEST_BOXES)
