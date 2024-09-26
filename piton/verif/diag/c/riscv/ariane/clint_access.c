#include <stdio.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.h"

#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn_64.c"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/encoding.h"


#define NHARTS       1
#define CLINT_BASE   0xfff1020000ULL

int main(int argc, char ** argv) {
    
  if(argv[0][0] == 0) {
      write_csr(0x300,0x8000000A00006008);
      write_csr(0x304,0x8);

      uint64_t *addr;
      // msip registers
      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + k*8);
//          printf("CLINT: msip %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("\n CLINT: msip addr %d = 0x%lx\n",k,addr);
//          printf("CLINT: result = 0x%016x\n",*addr);
          writeToAddress(addr,k*8,1);
          printf("CLINT: result = 0x%lx\n",*addr);
      }
      // mtimecmp registers
/*      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + 0x4000 + k*8);
          writeToAddress(addr,k*8,0x500);
          printf("CLINT: mtimecmp %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*addr);          
      }
      // mtime registers
      for (uint64_t k = 0; k < NHARTS; k++) {
          addr = (uint64_t*)(CLINT_BASE + 0xBFF8 + k*8);
          asm volatile ("wfi");
          printf("CLINT: mtime %d = addr 0x%08x 0x%08x\n",k,((uint64_t)addr)>>32,((uint64_t)addr) & 0xFFFFFFFF);
          printf("CLINT: result = 0x%016x\n",*addr);
      }*/
      printf(" This is the message for testing software interrupt handling. \n");
  }
      
  return 0;
}