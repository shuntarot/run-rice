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

../run_rice.f: ../rtl/rice_top.veryl ../Veryl.lock
	cd .. && veryl build

smoke.hex: ../asm/smoke.elf
	$(CROSS)objcopy -O binary $< smoke.bin
	python3 -I -c "import sys; b = open('smoke.bin', 'rb').read(); b += bytes(-len(b) % 4); \
	print('\n'.join('%08x' % int.from_bytes(b[i:i + 4], 'little') for i in range(0, len(b), 4)))" > $@

clean:
	rm -rf obj_dir sv sv.f smoke.bin smoke.hex
