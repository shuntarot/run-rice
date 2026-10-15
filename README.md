# run-rice

Runs the [rice](https://github.com/taichi-ishitani/rice) RISC-V core (RV32IM)
on a Digilent Arty A7-35 with
[veryl-harness](https://github.com/shuntarot/uharness).
Fetches and loads/stores go to two FPGA memories that the host fills first.

## Requirements

- Veryl, with `veryl-harness` and `hio` from veryl-harness
- Vivado
- An Arty A7-35 on USB
- rice, checked out beside this directory as `../rice`
- `riscv64-unknown-elf-gcc`, only to rebuild the test program

## Run

```bash
veryl harness gen --target digilent/arty-a7-35
make -C hns/syn
hio program
hio run bringup.hio
```

`bringup.hio` holds the core, loads `sw/smoke.elf` into both memories,
releases the core, and reads back what it wrote. The expected values are in
its comments.

## Files

| | |
|---|---|
| `src/rice_top.veryl` | the DUT: rice with its two buses turned into memory ports |
| `Harness.toml` | where each port goes |
| `sw/smoke.S` | the test program (`make -C sw`) |

## License

MIT (`LICENSE`).
