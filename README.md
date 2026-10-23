# run-rice

Runs the [rice](https://github.com/taichi-ishitani/rice) RISC-V core (RV32IM)
on a Digilent Arty A7-35 with
[veryl-harness](https://github.com/shuntarot/uharness).
Fetches read one 64 KB FPGA memory; loads and stores go to another. The host
fills both before the core starts.

## Requirements

- Veryl, with `veryl-harness` and `hio`
- Vivado
- An Arty A7-35 on USB
- Rust through rustup, for the firmware
- `qemu-system-riscv32`, to run the firmware without the board

## Run

```bash
veryl harness gen --target digilent/arty-a7-35
make -C hns/syn
hio program
hio run bringup.hio       # loads asm/smoke.elf and reads back what it wrote
```

Firmware in Rust: `hio cpu boot` loads it and shows its RTT console (Ctrl-A x
leaves). If `gen` wrote somewhere other than `hns/`, change `HIO_REGS` in
`.cargo/config.toml`.

```bash
cargo run -p hello
cargo run -p console
cargo run-emu -p console   # the same on QEMU
```

riscv-tests: `scripts/riscv-tests.sh <riscv-tests>/share/riscv-tests/isa`
(built for RV32).

## One address space, with the DRAM

`Harness.dram.toml` runs the core on `rtl/rice_mem_top.veryl`: 64 KB of FPGA
memory (`tcm`) from 0x8000_0000 and the board's DRAM (`dmem`) after it, so a
program of any size fits. It needs a board with a DRAM that the harness can
reach (not the PYNQ-Z1).

```bash
veryl harness gen --config Harness.dram.toml --out-dir hns_mem --target digilent/arty-a7-35
make -C hns_mem/syn
HIO_REGS=hns_mem/regs.json hio program
```

`picoruby/` runs a Ruby script on it with mruby/c (the same firmware as
run-hazard3's, for 40 MHz): `make -C picoruby`, then
`HIO_REGS=hns_mem/regs.json hio cpu boot picoruby/picoruby.elf`.
`make -C sim mem` runs `asm/mem.S` in Verilator; `make -C sim pico` runs the
firmware. Speed: [doc/performance.md](doc/performance.md).

## Size

LUT and FF counts, block RAM in 36 Kb blocks, after place and route. The
core is the DUT alone; the design adds the harness and the memory behind it
(block RAM, or the board's memory controller). The DRAM design includes it.

| Target | Clock | Core LUT / FF / BRAM / DSP | Design LUT / FF / BRAM / DSP |
|---|---|---|---|
| `digilent/arty-a7-35` | 40 MHz | 7,004 / 9,680 / 0 / 0 | 7,488 / 10,161 / 32 / 0 |
| `digilent/pynq-z1` | 40 MHz | 7,007 / 9,680 / 0 / 0 | 7,489 / 10,161 / 32 / 0 |
| `xilinx/vcu118` | 40 MHz | 6,988 / 9,678 / 0 / 0 | 7,468 / 10,159 / 32 / 0 |
| `digilent/arty-a7-35`, DRAM (`Harness.dram.toml`) | 40 MHz | 6,542 / 6,476 / 0 / 0 | 12,905 / 11,774 / 16 / 0 |

## Files

| | |
|---|---|
| `rtl/rice_top.veryl`, `Harness.toml` | the DUT with two block RAMs, and where each port goes |
| `rtl/rice_mem_top.veryl`, `Harness.dram.toml` | the DUT with FPGA memory and the DRAM in one address space |
| `bsp/`, `apps/` | the Rust firmware |
| `picoruby/` | mruby/c firmware |
| `asm/`, `sim/` | the test programs, and the DUTs in Verilator |

Put paths for your machine in `local.mk`; see `Makefile`.

## License

MIT (`LICENSE`).
