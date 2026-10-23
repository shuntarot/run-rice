# run-rice

Runs the [rice](https://github.com/taichi-ishitani/rice) RISC-V core (RV32IM)
on a Digilent Arty A7-35 with
[veryl-harness](https://github.com/shuntarot/uharness).
Fetches read one FPGA memory; loads and stores go to another. The host fills
both before the core starts.

## Requirements

- Veryl, with `veryl-harness` and `hio` from veryl-harness
- Vivado
- An Arty A7-35 on USB
- Rust through rustup, for the firmware (`rust-toolchain.toml` picks the target)
- `qemu-system-riscv32`, to run the firmware without the board

## Run

```bash
veryl harness gen --target digilent/arty-a7-35
make -C hns/syn
hio program
hio run bringup.hio
```

`bringup.hio` loads `asm/smoke.elf`, runs it, and reads back what it wrote.
The expected values are in its comments.

Firmware in Rust runs with cargo. `hio cpu boot` loads it, connects to its RTT
console, and exits with its status; Ctrl-A x leaves. If `veryl harness gen`
wrote somewhere other than `hns/` (`--out-dir`), change the path of
`HIO_REGS` under `[env]` in `.cargo/config.toml` to match.

```bash
cargo run -p hello
cargo run -p console
cargo run-emu -p console   # the same on QEMU's virt machine
```

riscv-tests' `isa` tests run one by one through `hio cpu boot`, each ending
with its pass or failure code (a test that hangs times out after 60 s):

```bash
scripts/riscv-tests.sh <riscv-tests>/share/riscv-tests/isa          # the suites this core runs
scripts/riscv-tests.sh -o results.txt <isa dir> 'rv32ui-p-*'   # or name them
```

The tests must be built for RV32 (`./configure --with-xlen=32` in riscv-tests).

## One address space, with the DRAM

`Harness.dram.toml` runs the core on a second DUT, `rtl/rice_mem_top.veryl`: the
two buses are served one at a time over 64 KB of FPGA memory (`tcm`) from
0x8000_0000 and the board's DRAM (`dmem`) right after it, as in run-hazard3.
A program of any size fits, at the price of speed: a fetch from `tcm` takes
two cycles, and one from the DRAM about thirty.

```bash
veryl harness gen --config Harness.dram.toml --out-dir hns_mem --target digilent/arty-a7-35
make -C hns_mem/syn
HIO_REGS=hns_mem/regs.json hio program
```

`picoruby/` runs a Ruby script on it with mruby/c (the same firmware as
run-hazard3's, built for 40 MHz): `make -C picoruby`, then
`HIO_REGS=hns_mem/regs.json hio cpu boot picoruby/picoruby.elf`. `make -C sim
mem` runs `asm/mem.S` on the DUT in Verilator (tcm, the DRAM, byte stores, a
misaligned load, code in the DRAM); `make -C sim pico` runs the firmware.

On the Arty at 40 MHz the core runs it at CPI about 9 (the same program and
instruction counts as on Hazard3, which is CPI 9 at 50 MHz): `fib(15)` takes
449 ms. The VM and the allocator are in `tcm`, as in run-hazard3 (`link.ld`).

## Size

LUT and FF counts, block RAM in 36 Kb blocks, after place and route. The
core is the DUT alone; the design adds the harness and the memory behind it
(block RAM, or the board's memory controller).

| Target | Clock | Core LUT / FF / BRAM / DSP | Design LUT / FF / BRAM / DSP |
|---|---|---|---|
| `digilent/arty-a7-35` | 40 MHz | 7,004 / 9,680 / 0 / 0 | 7,488 / 10,161 / 32 / 0 |
| `digilent/pynq-z1` | 40 MHz | 7,007 / 9,680 / 0 / 0 | 7,489 / 10,161 / 32 / 0 |
| `xilinx/vcu118` | 40 MHz | 6,988 / 9,678 / 0 / 0 | 7,468 / 10,159 / 32 / 0 |

## Files

| | |
|---|---|
| `rtl/rice_top.veryl` | the DUT: rice with its two buses turned into memory ports |
| `Harness.toml` | where each port goes |
| `rtl/rice_mem_top.veryl`, `Harness.dram.toml` | the DUT with one address space over FPGA memory and the DRAM |
| `picoruby/` | mruby/c firmware: startup, RTT, HAL and a Makefile |
| `asm/smoke.S` | the test program (`make asm`) |
| `bsp/` | startup, console (RTT, or the UART on QEMU) and exit for the firmware |
| `apps/` | the firmware: `hello`, `console` |
| `sim/` | the DUT alone in Verilator (`make sim`) |

Put paths for your machine in `local.mk`; see `Makefile`.

## License

MIT (`LICENSE`).
