-include ../local.mk
CROSS ?= riscv64-unknown-elf-

smoke.elf: smoke.S link.ld
	$(CROSS)gcc -march=rv32im_zicsr -mabi=ilp32 -nostdlib -static -T link.ld -o $@ $<

clean:
	rm -f *.elf

# The test for rice_mem_top, as the two memory images `veryl test` loads.
mem.elf: mem.S link_mem.ld
	$(CROSS)gcc -march=rv32im_zicsr -mabi=ilp32 -nostdlib -static -T link_mem.ld -o $@ $<

HEXPY = import sys; b = open(sys.argv[1], 'rb').read(); b += bytes(-len(b) % 4); \
	print('\n'.join('%08x' % int.from_bytes(b[i:i + 4], 'little') for i in range(0, len(b), 4)))

mem_tcm.hex mem_dmem.hex: mem.elf
	$(CROSS)objcopy -O binary -j .text $< mem_tcm.bin
	$(CROSS)objcopy -O binary -j .dram_text -j .dram_data $< mem_dmem.bin
	python3 -I -c "$(HEXPY)" mem_tcm.bin > mem_tcm.hex
	python3 -I -c "$(HEXPY)" mem_dmem.bin > mem_dmem.hex
	rm -f mem_tcm.bin mem_dmem.bin
