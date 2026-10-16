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

## Files

| | |
|---|---|
| `rtl/rice_top.veryl` | the DUT: rice with its two buses turned into memory ports |
| `Harness.toml` | where each port goes |
| `asm/smoke.S` | the test program (`make asm`) |
| `bsp/` | startup, console (RTT, or the UART on QEMU) and exit for the firmware |
| `apps/` | the firmware: `hello`, `console` |
| `sim/` | the DUT alone in Verilator (`make sim`) |

Put paths for your machine in `local.mk`; see `Makefile`.

## License

MIT (`LICENSE`).
