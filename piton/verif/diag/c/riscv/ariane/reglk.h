
#ifndef _RISCV_REGLK_H
#define _RISCV_REGLK_H

#include <stdint.h>

extern volatile uint64_t* reglk = 0xfff5206000;

int open_aes0();
int open_sha512();
int open_dma();
int open_hmac();
int open_acct();
int open_prng();

#endif
