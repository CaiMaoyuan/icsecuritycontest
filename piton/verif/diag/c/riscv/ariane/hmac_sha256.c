// See LICENSE for license details.

#include <string.h>
#include <stdio.h>
#include <encoding.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/hmac_sha256.h"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"

volatile uint64_t* hmac = 0xfff5203000 ;

int hmac_hashString(uint64_t *pString, uint64_t *hash, uint64_t use_key_hash)
{
    uint64_t *ptr = pString;
     

    // Send the message
 /*   while (readFromAddress(hmac, HMAC_READY) == 0) {
        do_delay(HMAC_READY_DELAY); 
    }*/

    writeMultiToAddress(hmac, HMAC_TEXT_BASE, pString, HMAC_TEXT_WORDS); 

    //strobeInit();
    if (use_key_hash) {
        writeToAddress(hmac, HMAC_NEXT_INIT, 0x5); 
        writeToAddress(hmac, HMAC_NEXT_INIT, 0x4); 
    } else {
        writeToAddress(hmac, HMAC_NEXT_INIT, 0x1);  //start hash
//        writeToAddress(hmac, HMAC_NEXT_INIT, 0x0); 
    }

    // wait for HMAC to start
    do_delay(20); 

    // wait for valid output
    while (readFromAddress(hmac, HMAC_VALID) == 0) {
        do_delay(HMAC_VALID_DELAY); 
    }

    // Read the Hash
    readMultiFromAddress(hmac, HMAC_HASH_BASE, hash, HMAC_HASH_WORDS); 

    return 0; 

}

int read_hmac_expectedHash()
{
    uint64_t expectedHash[HMAC_HASH_WORDS] = {0};
    readMultiFromAddress(hmac, HMAC_EXPECTEDHASH_BASE, expectedHash, HMAC_HASH_WORDS); 
    printf("hmac expected hash : %lx %lx %lx %lx\n", expectedHash[0], expectedHash[1], expectedHash[2], expectedHash[3]); 
    return 0;
}


int check_hmac()
{
    //// Give a test input and verify AES enryption
//    printf("    Verifying HMAC crypto engine ...\n") ;
   
    // Input for HMAC encyption

    uint64_t inputText[8] = {0x6162638000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000218};
    uint64_t hash[HMAC_HASH_WORDS];
    //modified by CMY--------------------------------------------------------------------------------------------------------------
    /*uint64_t expectedHash[HMAC_HASH_WORDS] = {0xe2fcbb9fe426e269,0xc1a1ade9c9d53cb7,0xa086fbf375836f93,0xd5761d020ecd9fe8};*/
    uint64_t expectedHash[HMAC_HASH_WORDS] = {0};
    //----------------------------------------------
    uint64_t key[8] = {0x0001020304050607, 0x08090a0b0c0d0e0f, 0x1011121314151617, 0x18191a1b1c1d1e1f, 0x2021222324252627, 0x28292a2b2c2d2e2f, 
    0x3031323334353637,0x38393a3b3c3d3e3f};
    
    int hmac_working; 
    int use_key_hash = 0; 

    writeMultiToAddress(hmac, HMAC_KEY_BASE, key, HMAC_KEY_WORDS); 

    // added for testing by CMY
    //asm volatile ("la x1 ");

    // call the hmac hashing function
    hmac_hashString(inputText, hash, use_key_hash);
    printf("hmac encrypted data : %lx %lx %lx %lx\n", hash[0], hash[1], hash[2], hash[3]); 

    // Verify the Hash 
    //addded by CMY---------------------------------------------------
 /*   uint64_t expectedHash_adversary[HMAC_HASH_WORDS] = {0x7cc8f39f45e69ffd ,0x484689d75c295677, 0xd4525d6e4d3bd9e9, 0x95b5bc9f01c966b3};
    writeMultiToAddress(hmac, HMAC_EXPECTEDHASH_BASE, expectedHash_adversary, HMAC_HASH_WORDS); */
    readMultiFromAddress(hmac, HMAC_EXPECTEDHASH_BASE, expectedHash, HMAC_HASH_WORDS); 
    printf("hmac expected hash : %lx %lx %lx %lx\n", expectedHash[0], expectedHash[1], expectedHash[2], expectedHash[3]); 
 /*   hmac_working = verifyMulti(expectedHash_adversary, hash, HMAC_HASH_WORDS);*/
    //------------------------------------------------------------------
   hmac_working = verifyMulti(expectedHash, hash, HMAC_HASH_WORDS);
    
    if (hmac_working)
        printf("    HMAC engine hashing successfully verified\n"); 
    else
        printf("    HMAC engine failed, disabling the crypto engine !\n");

    return hmac_working ;  
}


int guess_expectedHash()
{
    char inputText[65] = "----> this is the message to test performance couter <----";
    printf("inputText= %s\n", inputText) ;
    uint64_t expectedHash[HMAC_HASH_WORDS] = {0};
    readMultiFromAddress(hmac, HMAC_EXPECTEDHASH_BASE, expectedHash, HMAC_HASH_WORDS); 

    uint64_t mcycle_read0, mcycle_read1;
    uint64_t mcycle_used;
    int hmac_working; 

    mcycle_read0 = read_csr(0xb00);
    uint64_t hash_right[HMAC_HASH_WORDS]= {0xe2fcbb9fe426e269,0xc1a1ade9c9d53cb7,0xa086fbf375836f93,0xd5761d020ecd9fe8};
    hmac_working = verifyMulti(expectedHash, hash_right, HMAC_HASH_WORDS);
    mcycle_read1 = read_csr(0xb00);
    mcycle_used = mcycle_read1 - mcycle_read0;
    printf("mcycle_used= %lx , hamc_working = %d \n", mcycle_used,hmac_working);

    mcycle_read0 = read_csr(0xb00);
    uint64_t hash_wrong[HMAC_HASH_WORDS]= {0x0000000000000000,0x0,0xa0,0xd0};
    hmac_working = verifyMulti(expectedHash, hash_wrong, HMAC_HASH_WORDS);
    mcycle_read1 = read_csr(0xb00);
    mcycle_used = mcycle_read1 - mcycle_read0;
    printf("mcycle_used= %lx , hamc_working = %d \n", mcycle_used,hmac_working);
    

    return 0 ;
}

int _main (int argc, char ** argv)
{
    //guess_expectedHash();
    //check_hmac(); 
    return 0; 
}
