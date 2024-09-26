// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 26.11.2018
// Description: Simple hello world program that prints 32 times "hello world".
//

#include <stdio.h>
#include "/home/ICer/Desktop/openpiton-1/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/encoding.h"
#include "/home/ICer/Desktop/openpiton-1/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"

#include "/home/ICer/Desktop/openpiton-1/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"

#define CLINT_BASE   0xfff1020000ULL

int victim_fiction()
{
  printf("... this is a victim function...\n");

  return 0;
}

int main(int argc, char ** argv) {

/*    printf("the beginning of the victim fiction is : %lx \n", victim_fiction);
    uint64_t *plicaddr = 0xfff1100000;
    readFromAddress(plicaddr,0);
//    asm volatile ("wfi");
    
    uint64_t *clintaddr = 0xfff1020000;
      // misp registers
    for (uint64_t k = 0; k < 1; k++) {
          printf("CLINT: msip %d = addr 0x%08x 0x%08x\n",k,((uint64_t)clintaddr)>>32,((uint64_t)clintaddr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*clintaddr);
          writeToAddress(clintaddr,k*8,1);
          printf("CLINT: result = 0x%016x\n",*clintaddr);
    }

    printf("the beginning of the main fiction is : %lx \n", main);

    uint64_t pmpaddr2_read,pmpaddr3_read,pmpaddr4_read,pmpaddr5_read,pmpaddr6_read,pmpaddr7_read,pmpaddr8_read,pmpaddr9_read,pmpaddrA_read,pmpaddrB_read,pmpaddrC_read,pmpaddrD_read,pmpaddrE_read,pmpaddrF_read;
    uint64_t pmpcfg0_read,pmpcfg2_read;
    uint64_t pmpcfg0_write = 0x8f8f8f8f8f080808;
    uint64_t pmpcfg2_write = 0x8f8f8f8f8f8f8f8f;*/

/*    uint64_t mie_read = read_csr(0x304);
    printf("mie_read = 0x%016x\n",mie_read);*/
//    asm volatile ("mret");

  // mtimecmp registers
/*      uint64_t *mtimecmp_addr;
      mtimecmp_addr = (uint64_t*)(CLINT_BASE + 0x4000 );
      writeToAddress(mtimecmp_addr,0,0x100);
      //printf("CLINT: mtimecmp %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
      printf("CLINT: mtimecmp  = addr 0x%16x\n",((uint64_t)mtimecmp_addr));
      printf("CLINT: result = 0x%016x\n",*mtimecmp_addr);    
  
  // mtime registers
    uint64_t *mtime_addr;
    mtime_addr = (uint64_t*)(CLINT_BASE + 0xBFF8 );
    asm volatile ("wfi");
    printf("CLINT: mtime = addr 0x%016x\n",((uint64_t)mtime_addr));
    printf("CLINT: result = 0x%016x\n",*mtime_addr);      

  victim_fiction();
//  write_csr(0x304,0x80);
  write_csr(0xb00,0x1919f0);
  mie_read = read_csr(0x304);
  printf("mie_read = 0x%016x\n",mie_read);
  uint64_t mip_read = read_csr(0x344);
  printf("mip_read = 0x%016x\n",mip_read);
  uint64_t mcycle_read = read_csr(0xb00);
  printf("mcycle_read= %lx\n", mcycle_read);*/

  /*write_csr(0xb00,0x186000);*/
  /*write_csr(0xb00,0x100000);*/
  for (int k = 0; k < 32; k++) {
    // assemble number and print
    printf("Hello world, I am HART %d! Counting (%d of 32)...\n", argv[0][0], k);
  }

/*    write_csr(0x3A0,pmpcfg0_write);
    printf("write to pmpcfg0 successfully.\n"); 
    pmpcfg0_read = read_csr(0x3a0);
    printf("pmpcfg0_read= %llx\n", pmpcfg0_read); 
    write_csr(0x3b1,0x2000004c); //0x80000130>>2
    write_csr(0x3b2,0x20000234); // 0x800008d0>>2

    pmpaddr2_read = read_csr(0x3b2);
    printf("pmpaddr2_read= %lx\n", pmpaddr2_read);

    victim_fiction();*/

/*    write_csr(0x3a0,pmpcfg0_write);
    write_csr(0x3a2,pmpcfg2_write);

//  write_csr(0x300,0xfff1010000)
  printf("mstatus_read = %llx \n" ,mstatus_read);
  asm volatile ("mret");
  mstatus_read = read_csr(0x300);
  printf("mstatus_read = %llx \n" ,mstatus_read);

  for (int k = 0; k < 32; k++) {
    // assemble number and print
//    printf("Hello world, I am HART %d! Counting (%d of 32)...\n", argv[0][0], k);
      victim_fiction();
  }
  victim_fiction();
  printf("the beginning of the victim fiction is : %llx \n", victim_fiction);
//  printf("Done!\n");*/

  return 0;
}
