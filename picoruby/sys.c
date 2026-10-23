/* The few system calls newlib needs. Output goes to the RTT console. */

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/stat.h>

#include "rtt.h"

extern char __heap_start, __heap_end;

void *_sbrk(ptrdiff_t incr)
{
  static char *brk;
  if (!brk) brk = &__heap_start;
  if (brk + incr > &__heap_end) {
    errno = ENOMEM;
    return (void *)-1;
  }
  char *old = brk;
  brk += incr;
  return old;
}

int _write(int fd, const void *buf, size_t n) { (void)fd; rtt_write(buf, (int)n); return (int)n; }
int _read(int fd, void *buf, size_t n)        { (void)fd; (void)buf; (void)n; return 0; }
int _close(int fd)                            { (void)fd; return -1; }
int _fstat(int fd, struct stat *st)           { (void)fd; st->st_mode = S_IFCHR; return 0; }
int _isatty(int fd)                           { (void)fd; return 1; }
off_t _lseek(int fd, off_t off, int whence)   { (void)fd; (void)off; (void)whence; return 0; }
int _getpid(void)                             { return 1; }
int _kill(int pid, int sig)                   { (void)pid; (void)sig; errno = EINVAL; return -1; }

void _exit(int code)
{
  rtt_exit(code);
  for (;;) {}
}

/* newlib-nano's memcpy and memset go a byte at a time, and the core fetches
 * every byte through the memory controller, so they were a third of the
 * run time of mruby/c. These copy a word at a time when both sides line up.
 * A word access that does not line up would trap, so they never try one. */

void *memcpy(void *dst, const void *src, size_t n)
{
  unsigned char *d = dst;
  const unsigned char *s = src;

  if ((((uintptr_t)d ^ (uintptr_t)s) & 3) == 0) {
    while (n && ((uintptr_t)d & 3)) { *d++ = *s++; n--; }
    uint32_t *dw = (uint32_t *)d;
    const uint32_t *sw = (const uint32_t *)s;
    while (n >= 4) { *dw++ = *sw++; n -= 4; }
    d = (unsigned char *)dw;
    s = (const unsigned char *)sw;
  }
  while (n--) *d++ = *s++;
  return dst;
}

void *memset(void *dst, int c, size_t n)
{
  unsigned char *d = dst;
  uint32_t w = (unsigned char)c * 0x01010101u;

  while (n && ((uintptr_t)d & 3)) { *d++ = (unsigned char)c; n--; }
  uint32_t *dw = (uint32_t *)d;
  while (n >= 4) { *dw++ = w; n -= 4; }
  d = (unsigned char *)dw;
  while (n--) *d++ = (unsigned char)c;
  return dst;
}
