/* mruby/c HAL for Hazard3 on run-hazard3. No interrupts: time comes from the
 * CLINT-style `mtime`, and the scheduler's tick is taken when it is idle. */

#ifndef MRBC_SRC_HAL_H_
#define MRBC_SRC_HAL_H_

#define MRBC_TICK_UNIT 1
#define MRBC_TIMESLICE_TICK_COUNT 10

#ifdef __cplusplus
extern "C" {
#endif

void mrbc_tick(void);
void hal_idle(void);

#define mrbc_hal_init()        ((void)0)
#define mrbc_hal_enable_irq()  ((void)0)
#define mrbc_hal_disable_irq() ((void)0)
#define mrbc_hal_idle_cpu()    hal_idle()

int mrbc_hal_write(int fd, const void *buf, int nbytes);
int mrbc_hal_flush(int fd);
void mrbc_hal_abort(const char *s);

#ifdef __cplusplus
}
#endif
#endif
