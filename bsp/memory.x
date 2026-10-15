/* rice on run-rice's harness. Fetches go to imem and loads and stores to
 * dmem, 64 KB of FPGA memory each, both from 0x8000_0000, the reset PC.
 * `hio cpu boot` loads every segment into both, so the program is laid out
 * as if in one 64 KB memory: the core fetches its code from imem, and reads
 * and writes its data in dmem, where the host finds the RTT block. */

MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

REGION_ALIAS("REGION_TEXT",   RAM);
REGION_ALIAS("REGION_RODATA", RAM);
REGION_ALIAS("REGION_DATA",   RAM);
REGION_ALIAS("REGION_BSS",    RAM);
REGION_ALIAS("REGION_HEAP",   RAM);
REGION_ALIAS("REGION_STACK",  RAM);

_max_hart_id     = 0;
_hart_stack_size = 8K;
_heap_size       = 0;
