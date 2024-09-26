// See LICENSE for license details.

#include <string.h>
#include <stdio.h>
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/dma.h"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn.h"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/common_driver_fn.c"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/dma_function.c"
#include "/home/ICer/Desktop/openpiton/openpiton/piton/verif/diag/c/riscv/ariane/encoding.h"


volatile uint64_t* dma = 0xfff5207000;

int board_dma_init()
{
    
    //set dmacr_rs
    // dma_set_s2mm_dmacr((uint64_t *)dma,S2MM_DMACR_RS_MASK,1);
    dma_set_mm2s_dmacr((uint64_t *)dma,MM2S_DMACR_RS_MASK,1);
    //enable ioc interrupt
    // dma_set_s2mm_dmacr((uint64_t *)dma,S2MM_DMACR_IOC_IRQ_EN_MASK,1);
    dma_set_mm2s_dmacr((uint64_t *)dma,MM2S_DMACR_IOC_IRQ_EN_MASK,1);

}

int memory_overlap()
{
    writeToAddress(dma,0x1c,0x12345678);
    writeToAddress(dma,0x200,0xabcdef01);
    readFromAddress((uint64_t *)dma,0x200);
    return 0;
}

int main()
{

    /*uint64_t pmpcfg0_read,pmpcfg2_read, pmpaddr0_read,pmpaddr1_read;

    pmpcfg0_read = read_csr(0x3a0);
    printf("pmpcfg0_read= %lx\n", pmpcfg0_read);
    pmpaddr0_read = read_csr(0x3b0);
    printf("pmpaddr0_read= %lx\n", pmpaddr0_read);
    pmpaddr1_read = read_csr(0x3b1);
    printf("pmpaddr1_read= %lx\n", pmpaddr1_read);    

    uint64_t pmpcfg0_write = 0x00000a1a;
    uint64_t pmpaddr0_write = 0x3FFD480006; //0xFFF5200018>>2
    uint64_t pmpaddr1_write = 0x3FFD480008; //0xFFF5200020>>2

    write_csr(0x3a0,pmpcfg0_write);
    write_csr(0x3b0,pmpaddr0_write);
    write_csr(0x3b1,pmpaddr1_write);

    pmpcfg0_read = read_csr(0x3a0);
    printf("pmpcfg0_read= %lx\n", pmpcfg0_read);
    pmpaddr0_read = read_csr(0x3b0);
    printf("pmpaddr0_read= %lx\n", pmpaddr0_read);
    pmpaddr1_read = read_csr(0x3b1);
    printf("pmpaddr1_read= %lx\n", pmpaddr1_read);   

    board_dma_init();

    // TX
    //SET DMA DA LSB
    dma_set_mm2s_sa_lsb((uint64_t *)dma,0xF5200018);
    //SET DMA DA MSB
    dma_set_mm2s_sa_msb((uint64_t *)dma,0xFF);
    //SET DMA TRANS LENGTH
    dma_set_mm2s_length((uint64_t *)dma,0x00001000);

    int32_t DMACR,lsb,length;
    DMACR = dma_get_mm2s_dmacr((uint64_t *)dma);
    lsb = dma_get_mm2s_lsb((uint64_t *)dma);
    length = dma_get_mm2s_length((uint64_t *)dma);
    printf("DMACR : %x\n", DMACR);
    printf("lsb : %x\n", lsb);
    printf("length : %x\n", length);

    // TX
    //SET DMA DA LSB
    dma_set_mm2s_sa_lsb((uint64_t *)dma,0x00200000);
    //SET DMA DA MSB
    dma_set_mm2s_sa_msb((uint64_t *)dma,0x00000000);
    //SET DMA TRANS LENGTH
    dma_set_mm2s_length((uint64_t *)dma,0x00001000);

    DMACR = dma_get_mm2s_dmacr((uint64_t *)dma);
    lsb = dma_get_mm2s_lsb((uint64_t *)dma);
    length = dma_get_mm2s_length((uint64_t *)dma);
    printf("DMACR2 : %x\n", DMACR);
    printf("lsb2 : %x\n", lsb);
    printf("length2 : %x\n", length);*/

    memory_overlap();


    return 0;
}
