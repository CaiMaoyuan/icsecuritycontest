#include <string.h>
#include <stdio.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/acct.h"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"
#//include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"

volatile uint64_t* acct = 0xfff5205000;

int disable_aes_acct()
{ 
    
    printf("    unabling AES access... \n");
    writeToAddress((uint64_t *)acct, 0, 0x0f); 
    

    return 0;
}    

int enable_aes_acct()
{ 
    
//    printf("    enabling AES access... \n");
    writeToAddress((uint64_t *)acct, 0, 0xff); 
    

    return 0;
} 


int read_acct()
{
    
    uint32_t acct_mem[ACCT_MEM_WORDS] = {0};
    readMultiFromAddress(acct, ACCT_MEM_BASE, acct_mem, ACCT_MEM_WORDS);
    printf("acct configuration data : %x %x %x\n", acct_mem[0], acct_mem[1], acct_mem[2], acct_mem[3]); 

    return 0; 
}

int _____main()
{
  read_acct();
  return 0;
} 
