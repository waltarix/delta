ifeq ($(RUST_TARGET),)
	TARGET :=
	RELEASE_SUFFIX :=
else
	TARGET := $(RUST_TARGET)
	RELEASE_SUFFIX := -$(TARGET)
	export CARGO_BUILD_TARGET = $(RUST_TARGET)
endif

VERSION := $(subst $\",,$(word 3,$(shell grep -m1 "^version" Cargo.toml)))
RELEASE := delta-$(VERSION)$(RELEASE_SUFFIX)

DIST_DIR := dist
RELEASE_DIR := $(DIST_DIR)/$(RELEASE)
COMPLETIONS_DIR := $(RELEASE_DIR)/etc/completion

DELTA := target/$(TARGET)/release/delta

BINARY := $(RELEASE_DIR)/delta
COMPLETION_FILES := completion.bash completion.zsh
COMPLETIONS := $(addprefix $(COMPLETIONS_DIR)/,$(COMPLETION_FILES))

ARTIFACT := $(RELEASE).tar.xz

.PHONY: all
all: $(ARTIFACT)

$(DELTA):
	RUSTFLAGS='-C link-args=-s' cargo build --locked --release

$(DIST_DIR) $(RELEASE_DIR) $(COMPLETIONS_DIR):
	mkdir -p $@

$(BINARY): $(DELTA) $(RELEASE_DIR)
	cp -f $< $@

$(COMPLETIONS): $(COMPLETIONS_DIR)
	cp -f etc/completion/$(notdir $@) $@

$(ARTIFACT): $(BINARY) $(COMPLETIONS)
	tar -C $(DIST_DIR) -Jcvf $@ $(RELEASE)

.PHONY: clean
clean:
	$(RM) -rf $(ARTIFACT) $(DIST_DIR)
