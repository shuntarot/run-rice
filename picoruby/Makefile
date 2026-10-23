# mruby/c on run-hazard3: `make` builds picoruby.elf from hello.rb.
#
#   PICORUBY   the PicoRuby checkout (default ../../picoruby)
#   CROSS      toolchain prefix (default riscv32-unknown-elf-)
#   SCRIPTS    the Ruby scripts, up to four, each run as a task (default hello.rb)
#   OPT        optimization level (default -O2)
#   CPU_HZ     the core clock of the harness (default 40000000)
#
# Needs the toolchain on PATH, and `rake` in PICORUBY for the host mrbc
# (MRUBY_CONFIG=build_config/picorbc.rb rake).
#
#   hio cpu boot picoruby.elf

-include ../local.mk

PICORUBY ?= $(abspath ../../picoruby)
CROSS    ?= riscv32-unknown-elf-
OPT      ?= -O2
MRBC     ?= $(PICORUBY)/bin/mrbc
SCRIPTS  ?= hello.rb        # up to four; each becomes a task
CPU_HZ   ?= 40000000

MRUBYC = $(PICORUBY)/mrbgems/picoruby-mrubyc/lib/mrubyc
BUILD  = build

# The core cannot do a misaligned access, and bytecode has unaligned fields.
# NDEBUG drops mruby/c's debug code (it fills freed memory, among other things).
DEFS   = -DNDEBUG -DMRBC_REQUIRE_32BIT_ALIGNMENT=1 -DMRBC_SCHEDULER_EXIT=1 -DCPU_HZ=$(CPU_HZ)
ARCH   = -march=rv32im_zicsr_zifencei -mabi=ilp32
CFLAGS = $(ARCH) $(OPT) -g -ffunction-sections -fdata-sections -Wall \
         -I. -Ihal -I$(BUILD)/mrubyc/src -DMRBC_USE_STRING_UTF8=1 $(DEFS)
LDFLAGS = $(ARCH) -nostartfiles -specs=nano.specs -Wl,--gc-sections -Wl,--no-warn-rwx-segments -Wl,-T,link.ld

SRCS = main.c rtt.c sys.c
PROG_OBJS = $(foreach i,$(shell seq 0 $$(( $(words $(SCRIPTS)) - 1 ))),$(BUILD)/program$(i).o)
OBJS = $(addprefix $(BUILD)/, $(SRCS:.c=.o)) $(BUILD)/start.o $(PROG_OBJS)

picoruby.elf: $(OBJS) $(BUILD)/libmrubyc.a link.ld
	$(CROSS)gcc $(LDFLAGS) -o $@ $(OBJS) $(BUILD)/libmrubyc.a -lc -lgcc
	$(CROSS)size $@

$(BUILD)/%.o: %.c $(BUILD)/libmrubyc.a $(BUILD)/config.stamp
	@mkdir -p $(dir $@)
	$(CROSS)gcc $(CFLAGS) -fno-tree-loop-distribute-patterns -c -o $@ $<

$(BUILD)/start.o: start.S
	@mkdir -p $(BUILD)
	$(CROSS)gcc $(ARCH) -c -o $@ $<

# Rebuild when the scripts or the options change, not only when a file does.
$(BUILD)/scripts.stamp: FORCE
	@mkdir -p $(BUILD)
	@echo "$(SCRIPTS)" | cmp -s - $@ || echo "$(SCRIPTS)" > $@
$(BUILD)/config.stamp: FORCE
	@mkdir -p $(BUILD)
	@echo "$(OPT) $(DEFS) $(CROSS)" | cmp -s - $@ || echo "$(OPT) $(DEFS) $(CROSS)" > $@
FORCE:

# The scripts, compiled to bytecode on the host: the Nth is `program<N>`.
define PROGRAM
$(BUILD)/program$(1).c: $(word $(shell expr $(1) + 1),$(SCRIPTS)) $(BUILD)/scripts.stamp
	@mkdir -p $(BUILD)
	$(MRBC) -B program$(1) -o $$@ $$<
$(BUILD)/program$(1).o: $(BUILD)/program$(1).c $(BUILD)/config.stamp
	$(CROSS)gcc $(CFLAGS) -c -o $$@ $$<
endef
$(foreach i,$(shell seq 0 $$(( $(words $(SCRIPTS)) - 1 ))),$(eval $(call PROGRAM,$(i))))

# mruby/c itself, with the HAL of this directory. It builds in a copy of its
# source, because it writes generated headers beside it.
$(BUILD)/libmrubyc.a: hal/hal.h hal/hal.c rtt.h $(BUILD)/config.stamp
	@mkdir -p $(BUILD)/mrubyc
	cp -r $(MRUBYC)/src $(MRUBYC)/support $(MRUBYC)/mrblib $(BUILD)/mrubyc/
	mkdir -p $(BUILD)/mrubyc/hal && cp hal/hal.h hal/hal.c $(BUILD)/mrubyc/hal/ && cp rtt.h $(BUILD)/mrubyc/
	# alloc.c calls mrbc_printf without a declaration when NDEBUG is set.
	CFLAGS="$(ARCH) $(OPT) -ffunction-sections -fdata-sections $(DEFS) -Wno-error=implicit-function-declaration" \
	  $(MAKE) -C $(BUILD)/mrubyc/src MRBC_USE_HAL=../hal \
	  MRBC_USE_STRING_UTF8=1 CC=$(CROSS)gcc AR=$(CROSS)ar
	cp $(BUILD)/mrubyc/build/libmrubyc.a $@

clean:
	rm -rf $(BUILD) picoruby.elf

.PHONY: clean FORCE
