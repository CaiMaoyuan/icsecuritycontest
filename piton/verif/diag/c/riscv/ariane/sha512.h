// See LICENSE for license details.

#ifndef _RISCV_SHA512_H
#define _RISCV_SHA512_H

#include <stdint.h>
#include "common_driver_fn.h"

extern volatile uint64_t* sha512;


#define SHA512_READY_DELAY 1 
#define SHA512_VALID_DELAY 4 

// SHA512 peripheral
// SHA512 has no key, SHA512 key is only a place holder
#define SHA512_KEY_BITS   192
#define SHA512_KEY_WORDS (SHA512_KEY_BITS / BITS_PER_WORD)

#define SHA512_TEXT_BITS 1024
#define SHA512_HASH_BITS 512
#define SHA512_TEXT_BYTES (SHA512_TEXT_BITS / BITS_PER_BYTE )
#define SHA512_READY_WORDS 1
#define SHA512_NEXT_INIT_WORDS 1
#define SHA512_VALID_WORDS 1
#define SHA512_MODE_WORDS 1
#define SHA512_TEXT_WORDS (SHA512_TEXT_BITS / BITS_PER_WORD)
#define SHA512_HASH_WORDS (SHA512_HASH_BITS / BITS_PER_WORD)

#define SHA512_NEXT_INIT 0
#define SHA512_READY 0
#define SHA512_TEXT_BASE  ( SHA512_NEXT_INIT + SHA512_NEXT_INIT_WORDS )
#define SHA512_VALID      ( SHA512_TEXT_BASE + SHA512_TEXT_WORDS )
#define SHA512_MODE     ( SHA512_VALID     + SHA512_VALID_WORDS )
#define SHA512_HASH_BASE  ( SHA512_MODE     + SHA512_MODE_WORDS )


int sha512_hashString(uint32_t *pString, uint32_t *hash, uint32_t mode);
int sha512_addPadding(uint64_t pMessageBits64Bit, uint32_t* buffer);
int check_sha512(); 


#endif
