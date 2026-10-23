# The core starts here, in M-mode, at the reset vector in the FPGA memory.
# The host loads the program while the core is held in reset.

    .section .text.head, "ax"
    .global _start
_start:
    .option push
    .option norelax
    la   gp, __global_pointer$
    .option pop
    la   sp, __stack_top

    # Let the cycle and instruction counters run; the HAL's clock is one.
    csrw mcountinhibit, zero

    # DRAM keeps what an earlier run left in it.
    la   t0, __bss_start
    la   t1, __bss_end
1:  bgeu t0, t1, 2f
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    1b
2:
    call main
    mv   a0, a0
    call _exit
3:  j    3b
