#ifndef _RISCV_ACCT_H
#define _RISCV_ACCT_H

#include <stdint.h>
#include "common_driver_fn_64.h"

extern volatile uint64_t* acct;


#define HMAC_READY_DELAY 1 
#define HMAC_VALID_DELAY 4 

// ACCT peripheral
#define ACCT_MEM_BASE   0
#define ACCT_MEM_WORDS  3

#define HMAC_HASH_BITS 256
#define HMAC_TEXT_BYTES (HMAC_TEXT_BITS / BITS_PER_BYTE ) //64
#define HMAC_READY_WORDS 1
#define HMAC_NEXT_INIT_WORDS 1
#define HMAC_VALID_WORDS 1
#define HMAC_TEXT_WORDS (HMAC_TEXT_BITS / BITS_PER_WORD) //8
#define HMAC_HASH_WORDS (HMAC_HASH_BITS / BITS_PER_WORD) //4

#define HMAC_NEXT_INIT 0
#define HMAC_READY 0
#define HMAC_TEXT_BASE  ( HMAC_NEXT_INIT + HMAC_NEXT_INIT_WORDS ) //1
#define HMAC_VALID      ( HMAC_TEXT_BASE + HMAC_TEXT_WORDS ) //9
#define HMAC_HASH_BASE  ( HMAC_VALID     + HMAC_VALID_WORDS ) //10
#define HMAC_KEY_BASE   ( HMAC_HASH_BASE + HMAC_HASH_WORDS ) //14
#define HMAC_EXPECTEDHASH_BASE ( HMAC_KEY_BASE + HMAC_KEY_WORDS + HMAC_KEY_WORDS ) //22 // 2 kinds of keys

int disable_aes_acct();
int enable_aes_acct();
int read_acct(); 
int guess_expectedHash();

#endif