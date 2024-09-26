#include <string.h>
#include "reglk.h"
#include "common_driver_fn_64.h"

volatile uint64_t* reglk;

int open_aes0(){
    
    printf("    opening AES0 access... \n");
    writeToAddress((uint64_t *)reglk, 0, 0xffff00ff); 
    return 0;
} 

int open_sha512(){
    
    printf("    opening SHA-512 access... \n");
    writeToAddress((uint64_t *)reglk, 0, 0x00ffffff); 
    return 0;
} 

int open_dma(){
    
    printf("    opening DMA engine access... \n");
    writeToAddress((uint64_t *)reglk, 1, 0xffffff00); 
    return 0;
} 

int open_hmac(){
    
    printf("    opening HMAC access... \n");
    writeToAddress((uint64_t *)reglk, 1, 0xffff00ff); 
    return 0;
}

int open_acct(){
    
    printf("    opening ACCT access... \n");
    writeToAddress((uint64_t *)reglk, 1, 0xff00ffff); 
    return 0;
} 

int open_prng(){
    
    printf("    opening PRNG access... \n");
    writeToAddress((uint64_t *)reglk, 2, 0xff00ffff); 
    return 0;
} 

