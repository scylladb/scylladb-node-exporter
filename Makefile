SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
VERSION := $(shell sed 's/-.*//' VERSION)
ARCH := $(shell arch)
BUILD_DIR := build

ifeq ($(ARCH),x86_64)
GO_ARCH := amd64
else ifeq ($(ARCH),aarch64)
GO_ARCH := arm64
endif

TARBALL := $(BUILD_DIR)/node_exporter-$(VERSION).linux-$(GO_ARCH).tar.gz
DIRNAME := node_exporter-$(VERSION).linux-$(GO_ARCH)
BINARY := $(BUILD_DIR)/node_exporter
STRIPPED := $(BUILD_DIR)/node_exporter.stripped
DEBUGINFO := $(BUILD_DIR)/node_exporter.debug

.PHONY: all download extract strip clean

all: strip

download: $(TARBALL)

$(TARBALL):
	./download.sh --output-dir $(BUILD_DIR)

extract: $(BINARY)

$(BINARY): $(TARBALL)
	tar -C $(BUILD_DIR) -xf $(TARBALL) --no-same-owner
	mv $(BUILD_DIR)/$(DIRNAME)/node_exporter $(BINARY)
	rm -rf $(BUILD_DIR)/$(DIRNAME)
	# Preserve LICENSE and NOTICE from the tarball
	tar -C $(BUILD_DIR) -xf $(TARBALL) --no-same-owner $(DIRNAME)/LICENSE $(DIRNAME)/NOTICE 2>/dev/null || true
	mv $(BUILD_DIR)/$(DIRNAME)/LICENSE $(BUILD_DIR)/LICENSE 2>/dev/null || true
	mv $(BUILD_DIR)/$(DIRNAME)/NOTICE $(BUILD_DIR)/NOTICE 2>/dev/null || true
	rm -rf $(BUILD_DIR)/$(DIRNAME)

strip: $(STRIPPED)

$(STRIPPED): $(BINARY)
	objcopy --only-keep-debug $(BINARY) $(DEBUGINFO)
	cp $(BINARY) $(STRIPPED)
	strip $(STRIPPED)
	objcopy --add-gnu-debuglink=$(DEBUGINFO) $(STRIPPED)

clean:
	rm -rf $(BUILD_DIR)
