// See LICENSE for license details.

#include <string.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/sha512.h"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn.h"

#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn.c"

volatile uint64_t* sha512 = 0xfff5202000;


int sha512_hashString(uint32_t *pString, uint32_t *hash , uint32_t mode)
{
    {
//   uint32_t *ptr = pString;
    // printf("string: %x \n", *pString);

    // int done = 0;
    int firstTime = 1;
    // int totalBytes = 0;
    
    // while(!done) {
    //     uint32_t message[2 * SHA512_TEXT_BITS];
    //     for (int i=0; i<2*SHA512_TEXT_BYTES; i++)
    //         message[i] = 0; 
        
    //     // Copy next portion of string to message buffer
    //     uint32_t *msg_ptr = message;
    //     int length = 0;
    //     while(length < SHA512_TEXT_BYTES) {
    //         // Check for end of input
    //         if(*pString == '\0') {
    //             done = 1;
    //             break;
    //         }
    //         *msg_ptr++ = *pString++;
    //         ++length;
    //         ++totalBytes;
    //     }
        
        // Need to add padding if done
        // int addedBytes = 0;
        // if(done) {
        //     addedBytes = sha512_addPadding(totalBytes * BITS_PER_BYTE, message);
        // }
        
        // Send the message
        while (readFromAddress(sha512, SHA512_READY) == 0) {
            do_delay(SHA512_READY_DELAY); 
        }

        
        // printf("message: %x \n", message[0]);
        // printf("message: %x \n", message[2]);
        // writeMulticharToAddress(sha512, SHA512_TEXT_BASE, pString, SHA512_TEXT_BYTES); 
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

        //waitForReady ?

        // if data to send > 512 bits send again
        // printf("addedBytes: %d \n ", addedBytes);
        // if (addedBytes > SHA512_TEXT_BYTES) {
        //     while (readFromAddress(sha512, SHA512_READY) == 0) {
        //         do_delay(SHA512_READY_DELAY); 
        //     }

        //     writeMultiToAddress(sha512, SHA512_TEXT_BASE, (uint32_t *)(message + SHA512_TEXT_BYTES), SHA512_TEXT_WORDS); 

        //     // start the hashing
        //     //strobeNext();
        //     writeToAddress(sha512, SHA512_NEXT_INIT, 0x2); 
        //     writeToAddress(sha512, SHA512_NEXT_INIT, 0x0); 

        //     // wait for sha512 to start
        //     do_delay(300); 

        //     // wait for valid output
        //     while (readFromAddress(sha512, SHA512_VALID) == 0) {
        //         do_delay(SHA512_VALID_DELAY); 
        //     }
        // }
    }

    // Read the Hash
    readMultiFromAddress(sha512, SHA512_HASH_BASE, hash, SHA512_HASH_WORDS); 

    return 0; 

}


// int sha512_addPadding(uint64_t pMessageBits64Bit, uint32_t* buffer) {
//     int extraBits = pMessageBits64Bit % SHA512_TEXT_BITS;
//     int paddingBits = extraBits > 448 ? (2 * SHA512_TEXT_BITS) - extraBits : SHA512_TEXT_BITS - extraBits;
    
//     // Add size to end of string
//     const int startByte = extraBits / BITS_PER_BYTE;
//     const int sizeStartByte =  startByte + ((paddingBits / BITS_PER_BYTE) - 8);

//     for(int i = startByte; i < (sizeStartByte + 8); ++i) {
//         if(i == startByte) {
//             buffer[i] = 0x80; // 1 followed by many 0's
//         } else if( i >= sizeStartByte) {
//             int offset = i - sizeStartByte;
//             int shftAmnt = 56 - (8 * offset);
//             buffer[i] = (pMessageBits64Bit >> shftAmnt) & 0xFF;
//         } else {
//             buffer[i] = 0x0;
//         }
//     }
    
//     return (paddingBits / BITS_PER_BYTE);
// }


int check_sha512()
{
    //// Give a test input and verify AES enryption
    printf("    Verifying sha512 crypto engine ...\n") ;
   
    // Input for sha512 encyption
    uint32_t inputText[500] = {0x61626380, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
                                                                        0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                                                        0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                                                        0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00
                                                                        000000, 0x00000018};
    // printf("inputext: %s", inputText);
    //{0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 
                                                                        // 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa, 0xaaaaaaaa};
    //"Lincoln LaboratoLincoln LaboratoLincoln LaboratoLincoln Laborato";
    
    //char inputText[500] = "abc";
    uint32_t hash[SHA512_HASH_WORDS];
    uint32_t expectedHash[SHA512_HASH_WORDS] ={ 0xDDAF35A1, 0x93617ABA, 0xCC417349, 0xAE204131, 0x12E6FA4E, 0x89A97EA2, 0x0A9EEEE6, 0x4B55D39A, 
                                                                                0x2192992A, 0x274FC1A8, 0x36BA3C23, 0xA3FEEBBD, 0x454D4423, 0x643CE80E, 0x2A9AC94F, 0xA54CA49F};
    //  {0xf88c49e2, 0xb696d45a, 0x699eb10e, 0xffafb3c9, 0x522df6f7, 0xfa68c250, 0x9d105e84, 0x9be605ba};
    // {0xa6176daa, 0x94cfc9d7, 0xb9e1c0ce, 0x87ad72e2, 0xca85c77f, 0xb14333b2, 0xf102a066, 0xfb5f9eed, 
    //                                                                             0x63fd762b, 0x91556632, 0x874b630e, 0x0cfe5fed, 0xee9a01dd, 0xc0247a83, 0x90b83f0a, 0x48da01af};
    uint32_t mode = 3;
    // printf("mode : %d \n", mode);
    int sha512_working; 
    // call the sha512 hashing function
    sha512_hashString(inputText, hash, mode);
    printf("encrypted data : %x %x %x %x\n", hash[0], hash[1], hash[2], hash[3]); 
    printf("encrypted data : %x %x %x %x\n", hash[4], hash[5], hash[6], hash[7]); 
    printf("encrypted data : %x %x %x %x\n", hash[8], hash[9], hash[10], hash[11]); 
    printf("encrypted data : %x %x %x %x\n", hash[12], hash[13], hash[14], hash[15]); 

    // Verify the Hash 
    sha512_working = verifyMulti(expectedHash, hash, SHA512_HASH_WORDS); 
    
    if (sha512_working)
        printf("    sha512 engine hashing successfully verified\n"); 
    else
        printf("    sha512 engine failed, disabling the crypto engine !\n");

    return sha512_working ;  
}

int main ()
{
    check_sha512(); 
    return 0; 
}
