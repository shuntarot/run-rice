/* For rice_mem_top: code at the reset PC in the FPGA memory (tcm), and code
 * and data in the DRAM after it. */
SECTIONS
{
    . = 0x80000000;
    .text : { *(.text.start) *(.text*) }

    . = 0x80010000;
    .dram_text : { *(.dram_text) }

    . = 0x80011000;
    .dram_data : { *(.dram_data) }
}
