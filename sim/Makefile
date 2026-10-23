# make -C sim    runs asm/smoke.elf on rice_top in Verilator (5.x)
-include ../local.mk
CROSS     ?= riscv64-unknown-elf-
VERILATOR ?= verilator

run: obj_dir/Vtb smoke.hex
	obj_dir/Vtb

obj_dir/Vtb: tb.sv sv.f
	$(VERILATOR) --binary --timing -Wno-fatal -Wno-lint -Wno-style \
		--top-module tb tb.sv -f sv.f

# `veryl build` writes the sources of rice_top and everything it uses, in
# order, to run_rice.f. They are copied to sv/ with `x` in case items turned
# into `?`: rice's multiplier has items like 4'b0x01, where `x` matches
# anything (`case inside`). Vivado does so; Verilator 5 matches nothing, and
# the product comes out wrong.
sv.f: ../run_rice.f
	rm -rf sv
	mkdir sv
	for f in $$(cat $<); do \
		sed -E "/^\s*[0-9]+'b/ { :a; s/('b[01_?]*)x/\1?/; ta }" $$f > sv/$$(basename $$f); \
		echo sv/$$(basename $$f); \
	done > $@

../run_rice.f: $(wildcard ../rtl/*.veryl) ../Veryl.lock
	cd .. && veryl build

smoke.hex: ../asm/smoke.elf
	$(CROSS)objcopy -O binary $< smoke.bin
	python3 -I -c "import sys; b = open('smoke.bin', 'rb').read(); b += bytes(-len(b) % 4); \
	print('\n'.join('%08x' % int.from_bytes(b[i:i + 4], 'little') for i in range(0, len(b), 4)))" > $@

clean:
	rm -rf obj_dir obj_dir_mem obj_dir_pico sv sv.f smoke.bin smoke.hex mem_*.hex pico_*.hex pico_*.bin

# make -C sim mem    runs asm/mem.elf on rice_mem_top: tcm, the DRAM, byte and
# halfword stores, a misaligned load, and code that runs from the DRAM.
# make -C sim pico   runs picoruby/picoruby.elf (make -C picoruby first) and
# prints its RTT console.
MEM_CROSS ?= riscv32-unknown-elf-
HEXPY     = import sys; b = open(sys.argv[1], 'rb').read(); b += bytes(-len(b) % 4); \
	print('\n'.join('%08x' % int.from_bytes(b[i:i + 4], 'little') for i in range(0, len(b), 4)))

mem: obj_dir/Vtb_mem ../asm/mem_tcm.hex
	cp ../asm/mem_tcm.hex ../asm/mem_dmem.hex .
	obj_dir/Vtb_mem

obj_dir/Vtb_mem: tb_mem.sv sv.f
	$(VERILATOR) --binary --timing -Wno-fatal -Wno-lint -Wno-style \
		--top-module tb --Mdir obj_dir_mem -o Vtb_mem tb_mem.sv -f sv.f
	mkdir -p obj_dir && cp obj_dir_mem/Vtb_mem obj_dir/Vtb_mem

../asm/mem_tcm.hex: ../asm/mem.S ../asm/link_mem.ld
	$(MAKE) -C ../asm mem_tcm.hex

PICO_ELF = ../picoruby/picoruby.elf

pico: obj_dir/Vtb_pico $(PICO_ELF)
	$(MEM_CROSS)objcopy -O binary -j .head -j .tcm $(PICO_ELF) pico_tcm.bin
	$(MEM_CROSS)objcopy -O binary -j .text -j .rodata -j .data $(PICO_ELF) pico_dmem.bin
	python3 -I -c "$(HEXPY)" pico_tcm.bin > pico_tcm.hex
	python3 -I -c "$(HEXPY)" pico_dmem.bin > pico_dmem.hex
	obj_dir/Vtb_pico $(PICO_ARGS) +cb=$$($(MEM_CROSS)nm $(PICO_ELF) | awk '$$3 == "_SEGGER_RTT" {print $$1}')

obj_dir/Vtb_pico: tb_pico.sv sv.f
	$(VERILATOR) --binary --timing -Wno-fatal -Wno-lint -Wno-style \
		--top-module tb --Mdir obj_dir_pico -o Vtb_pico tb_pico.sv -f sv.f
	mkdir -p obj_dir && cp obj_dir_pico/Vtb_pico obj_dir/Vtb_pico

.PHONY: mem pico
