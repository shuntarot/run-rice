#include <stdint.h>

#include "mrubyc.h"
#include "rtt.h"

#ifndef CPU_HZ
#define CPU_HZ 50000000u
#endif

#ifndef MRBC_MEMORY_SIZE
#define MRBC_MEMORY_SIZE (256 * 1024)
#endif
static uint8_t memory_pool[MRBC_MEMORY_SIZE] __attribute__((aligned(8)));

/* The scripts of SCRIPTS, in order; each runs as a task. */
extern const uint8_t program0[], program1[] __attribute__((weak)),
  program2[] __attribute__((weak)), program3[] __attribute__((weak));

/* Counters for Ruby. mruby/c's Integer has 31 usable bits here, so these
 * return the low 30 bits: take a difference with `& 0x3fffffff`. */
static void c_cycles(mrbc_vm *vm, mrbc_value v[], int argc)
{
  uint32_t c;
  __asm__ volatile("csrr %0, mcycle" : "=r"(c));
  SET_INT_RETURN(c & 0x3fffffff);
}

static void c_instret(mrbc_vm *vm, mrbc_value v[], int argc)
{
  uint32_t c;
  __asm__ volatile("csrr %0, minstret" : "=r"(c));
  SET_INT_RETURN(c & 0x3fffffff);
}

/* The core clock in kHz, so a script can turn cycles into milliseconds. */
static void c_khz(mrbc_vm *vm, mrbc_value v[], int argc)
{
  SET_INT_RETURN(CPU_HZ / 1000);
}

int main(void)
{
  rtt_init();
  mrbc_init(memory_pool, MRBC_MEMORY_SIZE);
  mrbc_define_method(0, mrbc_class_object, "cycles", c_cycles);
  mrbc_define_method(0, mrbc_class_object, "instret", c_instret);
  mrbc_define_method(0, mrbc_class_object, "khz", c_khz);

  const uint8_t *programs[] = { program0, program1, program2, program3 };
  for (unsigned i = 0; i < sizeof programs / sizeof programs[0]; i++) {
    if (programs[i] && !mrbc_create_task(programs[i], NULL)) {
      rtt_write("cannot load a program\n", 22);
      return 2;
    }
  }
  return mrbc_run();
}
