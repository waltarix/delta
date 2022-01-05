ifeq ($(RUST_TARGET),)
	TARGET :=
	RELEASE_SUFFIX :=
else
	TARGET := $(RUST_TARGET)
	RELEASE_SUFFIX := -$(TARGET)
	export CARGO_BUILD_TARGET = $(RUST_TARGET)
endif

PROJECT_NAME := delta

VERSION := $(subst $\",,$(word 3,$(shell grep -m1 "^version" Cargo.toml)))
RELEASE := $(PROJECT_NAME)-$(VERSION)$(RELEASE_SUFFIX)

DIST_DIR := dist
RELEASE_DIR := $(DIST_DIR)/$(RELEASE)
COMPLETIONS_DIR := $(RELEASE_DIR)/etc/completion
MANUAL_DIR := $(RELEASE_DIR)/manual

BINARY := target/$(TARGET)/release/$(PROJECT_NAME)
MAN1 := etc/manual/$(PROJECT_NAME).1

RELEASE_BINARY := $(RELEASE_DIR)/$(PROJECT_NAME)
MANUAL := $(MANUAL_DIR)/$(PROJECT_NAME).1
COMPLETION_FILES := bash fish zsh
COMPLETIONS := $(addprefix $(COMPLETIONS_DIR)/completion.,$(COMPLETION_FILES))

ARTIFACT := $(RELEASE).tar.xz

.PHONY: all
all: $(ARTIFACT)

$(BINARY):
	cargo build --locked --release

$(MAN1): | $(RELEASE_BINARY)
	mkdir -p $(@D)
	env RELEASE_DIR=$(RELEASE_DIR) help2man -o $@ \
		-lN -m 'General Commands Manual' -L C.UTF-8 \
		./etc/bin/delta-for-help2man

$(DIST_DIR) $(RELEASE_DIR) $(COMPLETIONS_DIR) $(MANUAL_DIR):
	mkdir -p $@

$(RELEASE_BINARY): $(BINARY) $(RELEASE_DIR)
	cp -f $< $@

$(COMPLETIONS): $(COMPLETIONS_DIR)
	cp -f etc/completion/$(notdir $@) $@

$(MANUAL): $(MAN1) $(MANUAL_DIR)
	cp -f $< $@

$(ARTIFACT): $(RELEASE_BINARY) $(MANUAL) $(COMPLETIONS)
	tar -C $(DIST_DIR) -Jcvf $@ $(RELEASE)

.PHONY: clean
clean:
	$(RM) -r $(ARTIFACT) $(DIST_DIR) $(MAN1)
