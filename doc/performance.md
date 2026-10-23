# Performance and test results

Measured on a Digilent Arty A7-35.

## mruby/c on `rice_mem_top` (`picoruby/`)

Core clock 40 MHz. `picoruby/examples/bench.rb`; times are in ms.

| Job | rice, 40 MHz | Hazard3, 50 MHz |
|---|---|---|
| `fib(15)` | 449 | 373 |
| `3000.times { }` | 846 | 700 |
| `while` 3000 times | 180 | 150 |
| array, 1000 elements | 1019 | 845 |
| string, 500 appends | 270 | 223 |
| hash, 300 entries | 550 | 466 |
| CPI | about 9 | about 9 |

The same binary runs on both cores, and the instruction counts are equal. The
difference in time is the clock. The VM and the allocator are in `tcm`
(`picoruby/link.ld`); the stack and the heap are in the DRAM.

## Memory speed

On `rice_mem_top` the buses are served one at a time: a fetch from `tcm` takes
two cycles, and one from the DRAM about thirty. On `rice_top` (two block RAMs)
a fetch takes one cycle.

## riscv-tests

Not run yet on this core.
