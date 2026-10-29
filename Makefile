SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
VERSION := $(shell sed 's/-.*//' VERSION)
BUILD_DIR := build

BINARY := $(BUILD_DIR)/node_exporter
STRIPPED := $(BUILD_DIR)/node_exporter.stripped
DEBUGINFO := $(BUILD_DIR)/node_exporter.debug

.PHONY: all build strip test clean

all: strip

build: $(BINARY)

$(BINARY):
	./build.sh --output-dir $(BUILD_DIR)

strip: $(STRIPPED)

$(STRIPPED): $(BINARY)
	objcopy --only-keep-debug $(BINARY) $(DEBUGINFO)
	cp $(BINARY) $(STRIPPED)
	strip $(STRIPPED)
	objcopy --add-gnu-debuglink=$(DEBUGINFO) $(STRIPPED)

test:
	./build.sh --output-dir $(BUILD_DIR)/test --test

clean:
	rm -rf $(BUILD_DIR)
