# make asm       build asm/smoke.elf
# make sim       run asm/smoke.elf on rice_top in Verilator (5.x)
#
# Tools default to PATH. Put anything specific to your machine in local.mk
# (not committed):
#
#   VERILATOR = /path/to/verilator/bin/verilator
#   CROSS     = /path/to/riscv64-unknown-elf-

-include local.mk

.PHONY: asm sim

asm:
	$(MAKE) -C asm

sim:
	$(MAKE) -C sim
