CROSS ?= riscv64-unknown-elf-

smoke.elf: smoke.S link.ld
	$(CROSS)gcc -march=rv32im_zicsr -mabi=ilp32 -nostdlib -static -T link.ld -o $@ $<

clean:
	rm -f *.elf
