#include <stdint.h>

#include "hal.h"
#include "../rtt.h"

/* Time is the cycle counter, a CSR of every core, so the same HAL runs
 * wherever the core does. CPU_HZ is the core clock of the harness. */
#ifndef CPU_HZ
#define CPU_HZ     50000000u
#endif
#define TICK_CLKS  (CPU_HZ / 1000u)   /* 1 ms */

static inline uint32_t cycle_lo(void)
{
  uint32_t c;
  __asm__ volatile("csrr %0, mcycle" : "=r"(c));
  return c;
}

/* Waits for the next tick, then runs it. */
void hal_idle(void)
{
  static uint32_t next;
  uint32_t now = cycle_lo();
  if (next == 0) next = now;
  while ((int32_t)(cycle_lo() - next) < 0) {}
  next += TICK_CLKS;
  mrbc_tick();
}

int mrbc_hal_write(int fd, const void *buf, int nbytes)
{
  (void)fd;
  rtt_write(buf, nbytes);
  return nbytes;
}

int mrbc_hal_flush(int fd) { (void)fd; return 0; }

void mrbc_hal_abort(const char *s)
{
  if (s) {
    const char *p = s;
    while (*p) p++;
    rtt_write(s, (int)(p - s));
  }
  rtt_exit(1);
  for (;;) {}
}
