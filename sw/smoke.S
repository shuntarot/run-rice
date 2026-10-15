// Smoke test for rice on the FPGA harness.
// The same image is loaded into imem and dmem (both at 0x8000_0000). The core
// fetches from imem and writes its results to dmem at 0x8000_1000:
//   +0x00: 0x21534e48 ("HNS!")
//   +0x04: misa (0x40101110: RV32IMU, and E, which rice copies from I)
//   +0x08: mhartid
//   +0x0c: a word loaded from .rodata, so it came from dmem (0xc0ffee42)
//   +0x10: 1234 * 5678 / 7 (0x000f45f6)
//   +0x14: four byte stores (0x44332211)
//   +0x18: counter, incremented forever
#define RESULT 0x80001000

.section .text.start, "ax", @progbits
.globl _start
_start:
  li   t0, RESULT
  li   t1, 0x21534e48
  sw   t1, 0x00(t0)
  csrr t1, misa
  sw   t1, 0x04(t0)
  csrr t1, mhartid
  sw   t1, 0x08(t0)
  la   t2, pattern
  lw   t1, 0(t2)
  sw   t1, 0x0c(t0)
  li   t1, 1234
  li   t2, 5678
  mul  t1, t1, t2
  li   t2, 7
  divu t1, t1, t2
  sw   t1, 0x10(t0)
  li   t1, 0x11
  sb   t1, 0x14(t0)
  li   t1, 0x22
  sb   t1, 0x15(t0)
  li   t1, 0x33
  sb   t1, 0x16(t0)
  li   t1, 0x44
  sb   t1, 0x17(t0)
  li   t1, 0
1:
  addi t1, t1, 1
  sw   t1, 0x18(t0)
  j    1b

.section .rodata
.balign 4
pattern:
  .word 0xc0ffee42
