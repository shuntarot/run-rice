// Test for rice on rice_mem_top: one address space, 64 KB of FPGA memory (tcm)
// from 0x8000_0000 and the DRAM from 0x8001_0000. The results are written to
// tcm at 0x8000_1000, one word each:
//   +0x00: 0x21534e48 ("HNS!")
//   +0x04: a word written to the DRAM and read back (0x12345678)
//   +0x08: four byte stores to the DRAM, read back as a word (0x44332211)
//   +0x0c: two halfword stores to the DRAM (0x66665555)
//   +0x10: a word that was loaded into the DRAM (0xc0ffee42)
//   +0x14: a word read across two DRAM words, at +2 (0x22111234)
//   +0x18: the sum of 1 to 100, from code that runs from the DRAM (5050)
//   +0x1c: a value stored to the DRAM by that code, read back from tcm's side (0x00c0de00)
//   +0x20: a load right after a store to the DRAM (0x0badcafe)
//   +0x24: 0xdeadbeef, when everything above is done
#define RESULT 0x80001000
#define DRAM   0x80012000

.section .text.start, "ax", @progbits
.globl _start
_start:
  li   t0, RESULT
  li   t3, DRAM
  li   t1, 0x21534e48
  sw   t1, 0x00(t0)

  li   t1, 0x12345678
  sw   t1, 0(t3)
  lw   t2, 0(t3)
  sw   t2, 0x04(t0)

  li   t1, 0x11
  sb   t1, 4(t3)
  li   t1, 0x22
  sb   t1, 5(t3)
  li   t1, 0x33
  sb   t1, 6(t3)
  li   t1, 0x44
  sb   t1, 7(t3)
  lw   t2, 4(t3)
  sw   t2, 0x08(t0)

  li   t1, 0x5555
  sh   t1, 8(t3)
  li   t1, 0x6666
  sh   t1, 10(t3)
  lw   t2, 8(t3)
  sw   t2, 0x0c(t0)

  li   t4, 0x80011000
  lw   t2, 0(t4)
  sw   t2, 0x10(t0)

  lw   t2, 2(t3)
  sw   t2, 0x14(t0)

  // Code in the DRAM, called and returned from.
  li   t5, 0x80010000
  jalr ra, 0(t5)
  sw   a0, 0x18(t0)

  lw   t2, 0x10(t3)
  sw   t2, 0x1c(t0)

  li   t1, 0x0badcafe
  sw   t1, 0x14(t3)
  lw   t2, 0x14(t3)
  sw   t2, 0x20(t0)

  li   t1, 0xdeadbeef
  sw   t1, 0x24(t0)
1:
  j    1b

.section .dram_text, "ax", @progbits
dram_code:
  li   a0, 0
  li   a1, 1
  li   a2, 101
1:
  add  a0, a0, a1
  addi a1, a1, 1
  bne  a1, a2, 1b
  li   t1, 0x00c0de00
  li   t2, 0x80012010
  sw   t1, 0(t2)
  ret

.section .dram_data, "a", @progbits
.balign 4
  .word 0xc0ffee42
