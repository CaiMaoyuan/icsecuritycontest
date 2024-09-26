#include <string.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/sha512_64bit.h"
//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"

//#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"

volatile uint64_t* sha512 = 0xfff5202000;


int sha512_hashString(uint64_t *pString, uint64_t *hash , uint64_t mode)
{
    {
    int firstTime = 1;
        while (readFromAddress(sha512, SHA512_READY) == 0) {
            do_delay(SHA512_READY_DELAY); 
        }
        writeMultiToAddress((uint64_t *)sha512, SHA512_TEXT_BASE, pString, SHA512_TEXT_WORDS); 

        writeToAddress(sha512, SHA512_MODE, mode);
        // start the hashing
        if(firstTime) {
            //strobeInit();
            writeToAddress(sha512, SHA512_NEXT_INIT, 0x1); 
            writeToAddress(sha512, SHA512_NEXT_INIT, 0x0); 
            firstTime = 0;
        } else {
            //strobeNext();
            writeToAddress(sha512, SHA512_NEXT_INIT, 0x2); 
            writeToAddress(sha512, SHA512_NEXT_INIT, 0x0); 
        }

        // wait for sha512 to start
        do_delay(300); 

        // wait for valid output
        while (readFromAddress(sha512, SHA512_VALID) == 0) {
            do_delay(SHA512_VALID_DELAY); 
        }
    }

    // Read the Hash
    readMultiFromAddress(sha512, SHA512_HASH_BASE, hash, SHA512_HASH_WORDS); 

    return 0; 

}

int check_sha512()
{

    uint64_t inputText[16] = {0x6162638000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000018};
    
    uint64_t hash[SHA512_HASH_WORDS];
    uint64_t expectedHash[SHA512_HASH_WORDS] ={ 0xDDAF35A193617ABA, 0xCC417349AE204131, 0x12E6FA4E89A97EA2, 0x0A9EEEE64B55D39A, 
                                                                                0x2192992A274FC1A8, 0x36BA3C23A3FEEBBD, 0x454D4423643CE80E, 0x2A9AC94FA54CA49F};
    uint64_t mode = 3;
    // printf("mode : %d \n", mode);
    int sha512_working; 
    // call the sha512 hashing function
    sha512_hashString(inputText, hash, mode);
    printf("sha512 encrypted data : %lx %lx %lx %lx\n", hash[0], hash[1], hash[2], hash[3]); 
    printf("sha512 encrypted data : %lx %lx %lx %lx\n", hash[4], hash[5], hash[6], hash[7]); 

    // Verify the Hash 
    sha512_working = verifyMulti(expectedHash, hash, SHA512_HASH_WORDS); 

    return sha512_working ;  
}

int read_sha512_data()
{
    uint64_t inputText[16] = {0x6162638000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
                                                                        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000018};
    writeMultiToAddress((uint64_t *)sha512, SHA512_TEXT_BASE, inputText, SHA512_TEXT_WORDS); 
    uint64_t sha512_data[SHA512_TEXT_WORDS]= {};
    readMultiFromAddress(sha512, SHA512_TEXT_BASE, sha512_data, SHA512_TEXT_WORDS);  
    printf("sha512 data : %lx %lx %lx %lx\n", sha512_data[0], sha512_data[1], sha512_data[2], sha512_data[3]); 
    printf("sha512 data : %lx %lx %lx %lx\n", sha512_data[4], sha512_data[5], sha512_data[6], sha512_data[7]); 
    printf("sha512 data : %lx %lx %lx %lx\n", sha512_data[8], sha512_data[9], sha512_data[10], sha512_data[11]); 
    printf("sha512 data : %lx %lx %lx %lx\n", sha512_data[12], sha512_data[13], sha512_data[14], sha512_data[15]); 

    return 0;
}

int ____main ()
{
    check_sha512(); 
    return 0; 
}
