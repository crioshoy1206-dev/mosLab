CC := gcc
AR := ar
CFLAGS := -std=c99 -Wall -Wextra -Werror -pedantic -Iinclude -I.

BUILD_DIR := build
LIB_DIR := lib
VM_LIB := $(LIB_DIR)/libmosvm.a

MINIOS_SRCS := $(filter-out src/main.c,$(sort $(wildcard src/*.c)))
MINIOS_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(MINIOS_SRCS))
MAIN_OBJ := $(BUILD_DIR)/src/main.o

LABS := 01 02 03 04 05 06 07 08 09 10

HEADERS := $(sort $(wildcard include/minios/*.h include/mosvm/*.h))
APP_SRCS := $(sort $(wildcard apps/*.c))
TEST_SRCS := $(sort $(wildcard tests/*.c))
ALL_C_SRCS := $(sort $(wildcard src/*.c))
EXAMPLE_SRC := examples/example.c
EXAMPLE_BIN := $(BUILD_DIR)/example

.PHONY: help syntax-check verify-instructor minios example test clean $(addprefix demo-lab,$(LABS)) $(addprefix test-lab,$(LABS))

help:
	@printf '%s\n' 'miniOS lab targets:'
	@printf '  %-20s %s\n' 'make syntax-check' 'Compile-check public headers, src, apps, and tests'
	@printf '  %-20s %s\n' 'make verify-instructor' 'Run syntax checks and VM runtime tests'
	@printf '  %-20s %s\n' 'make minios' 'Link the student miniOS executable'
	@printf '  %-20s %s\n' 'make example' 'Build the standalone LAB0 VM example'
	@printf '  %-20s %s\n' 'make demo-labNN' 'Build and run one LAB demo, for NN=01..10'
	@printf '  %-20s %s\n' 'make test-labNN' 'Build and run one public LAB test, for NN=01..10'
	@printf '  %-20s %s\n' 'make test' 'Run all public LAB tests'
	@printf '  %-20s %s\n' 'make clean' 'Remove generated build outputs'

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(LIB_DIR):
	mkdir -p $@

$(BUILD_DIR)/tests/test_vm_runtime: tests/test_vm_runtime.c $(VM_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< $(VM_LIB) -o $@

$(BUILD_DIR)/syntax/header_check.c: $(HEADERS)
	@mkdir -p $(dir $@)
	@printf '%s\n' $(patsubst %, '#include "%"', $(HEADERS)) > $@
	@printf '%s\n' 'int main(void) { return 0; }' >> $@

syntax-check: $(BUILD_DIR)/syntax/header_check.c
	$(CC) $(CFLAGS) -fsyntax-only $<
	@for file in $(ALL_C_SRCS) $(APP_SRCS) $(TEST_SRCS); do \
		$(CC) $(CFLAGS) -fsyntax-only $$file || exit 1; \
	done

$(VM_LIB):
	@printf '%s\n' 'Missing trusted VM library: lib/libmosvm.a' >&2
	@printf '%s\n' 'Student builds do not regenerate this file. Use instructor/Makefile in CI or restore the distributed library.' >&2
	@exit 1

verify-instructor: syntax-check $(BUILD_DIR)/tests/test_vm_runtime
	$(BUILD_DIR)/tests/test_vm_runtime

minios: $(MAIN_OBJ) $(MINIOS_OBJS) $(VM_LIB)
	$(CC) $(CFLAGS) $(MAIN_OBJ) $(MINIOS_OBJS) $(VM_LIB) -o $(BUILD_DIR)/minios

$(EXAMPLE_BIN): $(EXAMPLE_SRC) $(VM_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< $(VM_LIB) -o $@

example: $(EXAMPLE_BIN)

define LAB_RULES
$(BUILD_DIR)/apps/lab$(1)_demo: apps/lab$(1)_*_demo.c $(MINIOS_OBJS) $(VM_LIB)
	@mkdir -p $$(dir $$@)
	$$(CC) $$(CFLAGS) $$< $$(MINIOS_OBJS) $$(VM_LIB) -o $$@

demo-lab$(1): $(BUILD_DIR)/apps/lab$(1)_demo
	$$<

$(BUILD_DIR)/tests/test_lab$(1): tests/test_lab$(1)_*.c $(MINIOS_OBJS) $(VM_LIB)
	@mkdir -p $$(dir $$@)
	$$(CC) $$(CFLAGS) $$< $$(MINIOS_OBJS) $$(VM_LIB) -o $$@

test-lab$(1): $(BUILD_DIR)/tests/test_lab$(1)
	$$<
endef

$(foreach lab,$(LABS),$(eval $(call LAB_RULES,$(lab))))

test: $(addprefix test-lab,$(LABS))

clean:
	rm -rf $(BUILD_DIR)
