// See LICENSE for license details.

#include <string.h>
#include <stdio.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/aes0.h"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/reglk.c"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"

//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/acct.c"


volatile uint64_t* aes = 0xfff5200000 ;

int aes_start_encrypt(uint64_t *pt)
{
    // Write the inputs
    writeMultiToAddress((uint64_t *)aes, AES_PT_BASE, pt, AES_PT_WORDS); 
    // Start the AES encryption
    writeToAddress((uint64_t *)aes, AES_START, 0x1);

    // Wait to see that START has been asserted to make sure DONE has a valid value
    while (readFromAddress((uint64_t *)aes, AES_START) == 0) {
        do_delay(AES_START_DELAY); 
    }
    writeToAddress((uint64_t *)aes, AES_START, 0x0);

    return 0; 

}

/*volatile uint64_t* acct = 0xfff5205000;   

int enable_aes_acct()
{ 
    
    printf("    enabling AES access... \n");
    writeToAddress((uint64_t *)acct, 0, 0xff); 
    

    return 0;
} */

int aes_wait()
{
     // Wait for valid output
    while (readFromAddress((uint64_t *)aes, AES_DONE) == 0) {
        do_delay(AES_DONE_DELAY); 
    }

    return 0; 

}

int aes_data_out(uint64_t *ct)
{
    // Read the Encrypted data
    readMultiFromAddress((uint64_t *)aes, AES_CT_BASE, ct, AES_CT_WORDS);
    return 0; 
}


int aes_encrypt(uint64_t *pt,  uint64_t *ct)
{
    aes_start_encrypt(pt); 
    aes_wait();
    aes_data_out(ct); 
    return 0; 
}

int check_aes()
{
    //// Give a test input and verify AES enryption
    printf("    Verifying AES crypto engine ...\n") ;
    set_aes_rw_policy(1);
    // Input for AES encyption
    uint64_t pt[2]  = {0x0011223344556677, 0x8899aabbccddeeff}; 
    
    uint64_t key0[2] = {0xffffffffffffffff, 0xffffffffffffffff};
    uint64_t ct[AES_CT_WORDS];
    uint64_t expectedCt0[AES_CT_WORDS] = {0xa90e5b74d2807a6, 0x51f69ac0896a09f6};

    int aes_working; 

    write_aes_key(0);
    aes_encrypt(pt, ct); 

    

    printf("    encrypted data0 : %lx %lx\n", ct[0], ct[1]); 

    // Verify the Encrypted data
    aes_working = verifyMulti(expectedCt0, ct, AES_CT_WORDS); 

    if (aes_working)
        printf("    AES engine key0 encryption successfully verified\n"); 
    else
        printf("    AES engine key0 failed, disabling the crypto engine !\n");
    return aes_working ;  
    
}

 int write_aes_key(int use_rng)
 {
    if(use_rng){
        printf("    Use LFSR to generate random key \n");
        writeToAddress((uint64_t *)aes, AES_KEY_UPDATE, 0x1); 
    }
    else{
        uint64_t key0[2] = {0xffffffffffffffff, 0xffffffffffffffff};
        writeMultiToAddress((uint64_t *)aes, AES_KEY0_BASE, key0, AES_KEY_WORDS); 
    }
    return 0;
 }

int set_aes_rw_policy(uint64_t enable)
{
    if(enable)
    {
//        printf("    enabling AES read and write... \n");
        writeToAddress((uint64_t *)aes, AES_KEY_READ_WRITE_POLICY, enable); 
    }
    else 
    {
        printf("    unabling AES read and write... \n");
        writeToAddress((uint64_t *)aes, AES_KEY_READ_WRITE_POLICY, enable); 
    }
    return 0;
}

 int read_aes_key(/*uint64_t key_sel , */char inputpassword[20])
 {
    enable_aes_acct();
    set_aes_rw_policy(1);
    write_aes_key(0);
    uint64_t key0[2] = {0x0001020304050607, 0x08090a0b0c0d0e0f};
    //writeMultiToAddress((uint64_t *)aes, AES_KEY0_BASE, key0, AES_KEY_WORDS); */

    char password[20] = "123456";
    if(strcmp(password,inputpassword) ==0 ){
        readMultiFromAddress((uint64_t *)aes, AES_KEY0_BASE, key0, AES_KEY_WORDS);
        printf("aes key0 : %lx %lx\n ", key0[0], key0[1]);  
    }
    else
        printf("incorrect password, exit...\n"); 
    return 0;
 }

int __main ()
{
    enable_aes_acct();
    open_aes0();
    check_aes(0);

    return 0; 
}
