// See LICENSE for license details.

#ifndef _RISCV_AES_H
#define _RISCV_AES_H

#include <stdint.h>

extern volatile uint64_t* aes;
extern volatile uint64_t* acct;

#define AES_START_DELAY 1
#define AES_DONE_DELAY 4

// peripheral registers
#define AES_NO_KEYS 3
#define AES_PT_BITS   128
#define AES_ST_BITS   128
#define AES_KEY_BITS   128
#define AES_CT_BITS   128
#define AES_START_WORDS  1
#define AES_DONE_WORDS   1
#define AES_PT_WORDS (AES_PT_BITS / BITS_PER_WORD)  //2
#define AES_KEY_WORDS (AES_KEY_BITS / BITS_PER_WORD) //2
#define AES_CT_WORDS (AES_CT_BITS / BITS_PER_WORD) //2

#define AES_KEY_UPDATE_WORD 1
#define AES_SHIFT_IDX_WORD 1
#define AES_CYCLE_WORD 1

#define AES_START   0
#define AES_PT_BASE   ( AES_START     + AES_START_WORDS ) //1 // plain text
#define AES_KEY0_BASE ( AES_PT_BASE   + AES_PT_WORDS ) //3
#define AES_DONE      ( AES_KEY0_BASE + AES_KEY_WORDS ) //5
#define AES_CT_BASE   ( AES_DONE      + AES_DONE_WORDS ) //6
#define AES_KEY_UPDATE (AES_CT_BASE + AES_CT_WORDS)//8
#define AES_SHIFT_IDX (AES_KEY_UPDATE + AES_KEY_UPDATE_WORD)//9
#define AES_CYCLE (AES_SHIFT_IDX + AES_SHIFT_IDX_WORD)//10
#define AES_KEY_READ_WRITE_POLICY (AES_CYCLE + AES_CYCLE_WORD)//11


int aes_start_encrypt(uint64_t *pt); 
int aes_wait(); 
int aes_data_out(uint64_t *ct); 
int aes_encrypt(uint64_t *pt, uint64_t *ct);
int set_aes_rw_policy(uint64_t enable);
int write_aes_key(int use_rng);
//int enable_aes_acct();
 int read_aes_key(/*uint64_t key_sel , */char inputpassword[20]);

#endif
