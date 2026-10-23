/* A SEGGER RTT control block with the channels `hio cpu boot` expects: up 0
 * and down 0 are the terminal, and up 1, named "hio-exit", carries the exit
 * status. */

#include <stdint.h>
#include <string.h>

#include "rtt.h"

#define UP_SIZE   4096
#define EXIT_SIZE 16
#define DOWN_SIZE 64

/* Wait for the host rather than lose output. */
#define MODE_BLOCK_IF_FULL 2

typedef struct {
  const char *name;
  char *buf;
  uint32_t size;
  volatile uint32_t wr;
  volatile uint32_t rd;
  uint32_t flags;
} rtt_buffer;

/* hio finds the block by this name. */
struct {
  char id[16];
  int32_t max_up;
  int32_t max_down;
  rtt_buffer up[2];
  rtt_buffer down[1];
} _SEGGER_RTT;

static char up0[UP_SIZE], up1[EXIT_SIZE], down0[DOWN_SIZE];

void rtt_init(void)
{
  _SEGGER_RTT.max_up = 2;
  _SEGGER_RTT.max_down = 1;
  _SEGGER_RTT.up[0]   = (rtt_buffer){ "Terminal", up0, UP_SIZE,   0, 0, MODE_BLOCK_IF_FULL };
  _SEGGER_RTT.up[1]   = (rtt_buffer){ "hio-exit", up1, EXIT_SIZE, 0, 0, MODE_BLOCK_IF_FULL };
  _SEGGER_RTT.down[0] = (rtt_buffer){ "Terminal", down0, DOWN_SIZE, 0, 0, 0 };
  /* The host finds the block by its id, so it goes in last. */
  __asm__ volatile("fence" ::: "memory");
  memcpy(_SEGGER_RTT.id, "SEGGER RTT\0\0\0\0\0\0", 16);
}

static void put(rtt_buffer *b, const char *p, int len)
{
  while (len > 0) {
    uint32_t wr = b->wr, rd = b->rd;
    uint32_t room = (rd > wr) ? rd - wr - 1 : b->size - wr - (rd == 0 ? 1 : 0);
    if (room == 0) continue;
    uint32_t n = (uint32_t)len < room ? (uint32_t)len : room;
    memcpy(b->buf + wr, p, n);
    __asm__ volatile("fence" ::: "memory");
    b->wr = (wr + n) % b->size;
    p += n;
    len -= n;
  }
}

void rtt_write(const char *buf, int len) { put(&_SEGGER_RTT.up[0], buf, len); }

void rtt_exit(int code)
{
  char c = (char)code;
  put(&_SEGGER_RTT.up[1], &c, 1);
}

int rtt_getc(void)
{
  rtt_buffer *b = &_SEGGER_RTT.down[0];
  if (b->rd == b->wr) return -1;
  int c = (unsigned char)b->buf[b->rd];
  b->rd = (b->rd + 1) % b->size;
  return c;
}
