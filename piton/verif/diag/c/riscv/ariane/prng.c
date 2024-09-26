
#include <stdio.h>
#include <string.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/prng.h"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"

//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"

volatile uint64_t* prng = 0xfff5208000;

int check_prng()
{
    printf("    Verifying prng function ...\n") ;

    uint64_t expectedPrng[PRNG_RANDNUM_WORDS_64]= {0xbe19abf1b93784bf};
    uint64_t rand_num[PRNG_RANDNUM_WORDS_64]= {};
    uint64_t inputSeed[PRNG_SEED_WORDS_64] = {0x123456789abcdef};
    writeMultiToAddress((uint64_t *)prng, PRNG_SEED_BASE, inputSeed, PRNG_SEED_WORDS_64); 

    uint64_t inputPoly[PRNG_POLY64_WORDS] = {0xabcdef123456789};
    writeMultiToAddress((uint64_t *)prng, PRNG_POLY64_BASE, inputPoly, PRNG_POLY64_WORDS); 

    writeToAddress((uint64_t *)prng,PRNG_MODE_BASE,0);
    writeToAddress((uint64_t *)prng,SEED_INPUT_DONE_BASE,1);

    while (readFromAddress(prng, RAND_NUM_VALID_BASE) == 0) {
        do_delay(RAND_NUM_VALID_DELAY); 
    }
        readMultiFromAddress(prng, PRNG_RANDNUM64_BASE, rand_num, PRNG_RANDNUM_WORDS_64);     
        printf("random data : %lx \n", rand_num[0]); 

        int prng_working;
        prng_working = verifyMulti(expectedPrng, rand_num, PRNG_RANDNUM_WORDS_64);
    
    
    if (prng_working)
        printf("    PRNG engine successfully verified\n"); 
    else
        printf("    PRNG engine failed, disabling the crypto engine !\n");

    return prng_working ;  

    return 0;
}

int read_prng_seed()
{
    uint64_t inputSeed128[PRNG_SEED_WORDS_128] = {0x0123456789abcdef,0xfedcba9876543210};
    writeMultiToAddress((uint64_t *)prng, PRNG_SEED_BASE, inputSeed128, PRNG_SEED_WORDS_128); 
    uint64_t prng_seeds[PRNG_SEED_WORDS_128]= {};
    readMultiFromAddress(prng, PRNG_SEED_BASE, prng_seeds, PRNG_RANDNUM_WORDS_128);  
    printf("prng seeds : %lx %lx \n", prng_seeds[0],prng_seeds[1]); 
    return 0;
}

int ___main ()
{
    check_prng(); 
    return 0; 
}