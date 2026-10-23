#ifndef RTT_H
#define RTT_H

void rtt_init(void);
void rtt_write(const char *buf, int len);
/* Reads one byte the host typed; -1 if there is none. */
int  rtt_getc(void);
/* Tells `hio cpu boot` the exit status. */
void rtt_exit(int code);

#endif
