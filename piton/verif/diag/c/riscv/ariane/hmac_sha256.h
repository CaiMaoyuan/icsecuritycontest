
#ifndef _RISCV_HMAC_SHA256_H
#define _RISCV_HMAC_SHA256_H

#include <stdint.h>

extern volatile uint64_t* hmac;


#define HMAC_READY_DELAY 1 
#define HMAC_VALID_DELAY 4 

// HMAC peripheral
#define HMAC_KEY_BITS   512
#define HMAC_KEY_WORDS (HMAC_KEY_BITS / BITS_PER_WORD) //8

#define HMAC_TEXT_BITS 512
#define HMAC_TEXT_WORDS (HMAC_TEXT_BITS / BITS_PER_WORD) //8
#define HMAC_HASH_BITS 256
#define HMAC_READY_WORDS 1
#define HMAC_NEXT_INIT_WORDS 1
#define HMAC_VALID_WORDS 1
#define HMAC_TEXT_WORDS (HMAC_TEXT_BITS / BITS_PER_WORD) //8
#define HMAC_HASH_WORDS (HMAC_HASH_BITS / BITS_PER_WORD) //4

#define HMAC_NEXT_INIT 0
#define HMAC_READY 0
#define HMAC_TEXT_BASE  1
#define HMAC_VALID      17
#define HMAC_HASH_BASE  18
#define HMAC_KEY_BASE   34
#define HMAC_EXPECTEDHASH_BASE 42 

int hmac_hashString(uint64_t *pString, uint64_t *hash, uint64_t use_key_hash);
int check_hmac(); 
int guess_expectedHash();
int read_hmac_expectedHash();

#endif
