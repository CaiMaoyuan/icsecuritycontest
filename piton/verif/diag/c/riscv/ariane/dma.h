// See LICENSE for license details.

#ifndef _RISCV_DMA_H
#define _RISCV_DMA_H

#include <stdint.h>

extern volatile uint64_t* dma;

#define DMA_START_DELAY 2
#define DMA_DONE_DELAY 100


// peripheral registers
#define MM2S_DMACR      0x00
#define MM2S_DMASR      0x04
#define MM2S_SA         0x18
#define MM2S_SA_MSB     0x1C
#define MM2S_LENGTH     0x28
#define S2MM_DMACR      0x30
#define S2MM_DMASR      0x34
#define S2MM_DA         0x48
#define S2MM_DA_MSB     0x4C
#define S2MM_LENGTH     0x58


//dma mm2s_dmacr offset
#define MM2S_DMACR_RS_OFS               0
#define MM2S_DMACR_RESET_OFS            2
#define MM2S_DMACR_KEYHOLE_OFS          3
#define MM2S_DMACR_CYCLIC_BD_EN_OFS     4
#define MM2S_DMACR_IOC_IRQ_EN_OFS       12
#define MM2S_DMACR_DLY_IRQ_EN_OFS       13
#define MM2S_DMACR_ERR_IRQ_EN_OFS       14


//dma mm2s_dmacr mask
#define MM2S_DMACR_RS_MASK              (1<<MM2S_DMACR_RS_OFS)
#define MM2S_DMACR_RESET_MASK           (1<<MM2S_DMACR_RESET_OFS)
#define MM2S_DMACR_KEYHOLE_MASK         (1<<MM2S_DMACR_KEYHOLE_OFS)
#define MM2S_DMACR_CYCLIC_BD_EN_MASK    (1<<MM2S_DMACR_CYCLIC_BD_EN_OFS)
#define MM2S_DMACR_IOC_IRQ_EN_MASK      (1<<MM2S_DMACR_IOC_IRQ_EN_OFS)
#define MM2S_DMACR_DLY_IRQ_EN_MASK      (1<<MM2S_DMACR_DLY_IRQ_EN_OFS)
#define MM2S_DMACR_ERR_IRQ_EN_MASK      (1<<MM2S_DMACR_ERR_IRQ_EN_OFS)
#define MM2S_DMACR_IRQ_THRESHOLD_MASK   0xFF0000
#define MM2S_DMACR_IRQ_DELAY_MASK       0xFF00000000

//dma mm2s_dmasr offset
#define MM2S_DMASR_HALTED_OFS           0
#define MM2S_DMASR_IDLE_OFS             1
#define MM2S_DMASR_SGINCLD_OFS          3
#define MM2S_DMASR_DMA_INT_ERR_OFS      4
#define MM2S_DMASR_DMA_SLV_ERR_OFS      5
#define MM2S_DMASR_DMA_DEC_ERR_OFS      6
#define MM2S_DMASR_SG_INT_ERR_OFS       8
#define MM2S_DMASR_SG_SLV_ERR_OFS       9
#define MM2S_DMASR_SG_DEC_ERR_OFS       10
#define MM2S_DMASR_IOC_IRQ_OFS          12
#define MM2S_DMASR_DLY_IRQ_OFS          13
#define MM2S_DMASR_ERR_IRQ_OFS          14

//dma mm2s_dmaSR mask
#define MM2S_DMASR_HALTED_MASK              (1<<MM2S_DMASR_HALTED_OFS)
#define MM2S_DMASR_IDLE_MASK                (1<<MM2S_DMASR_IDLE_OFS)
#define MM2S_DMASR_SGINCLD_MASK             (1<<MM2S_DMASR_SGINCLD_OFS)
#define MM2S_DMASR_DMA_INT_ERR_MASK         (1<<MM2S_DMASR_DMA_INT_ERR_OFS)
#define MM2S_DMASR_DMA_SLV_ERR_MASK         (1<<MM2S_DMASR_DMA_SLV_ERR_OFS)
#define MM2S_DMASR_DMA_DEC_ERR_MASK         (1<<MM2S_DMASR_DMA_DEC_ERR_OFS)
#define MM2S_DMASR_SG_INT_ERR_MASK          (1<<MM2S_DMASR_SG_INT_ERR_OFS)
#define MM2S_DMASR_SG_SLV_ERR_MASK          (1<<MM2S_DMASR_SG_SLV_ERR_OFS)
#define MM2S_DMASR_SG_DEC_ERR_MASK          (1<<MM2S_DMASR_SG_DEC_ERR_OFS)
#define MM2S_DMASR_IOC_IRQ_MASK             (1<<MM2S_DMASR_IOC_IRQ_OFS)
#define MM2S_DMASR_DLY_IRQ_MASK             (1<<MM2S_DMASR_DLY_IRQ_OFS)
#define MM2S_DMASR_ERR_IRQ_MASK             (1<<MM2S_DMASR_ERR_IRQ_OFS)
#define MM2S_DMASR_IRQ_THRESHOLD_STS_MASK   0xFF0000
#define MM2S_DMASR_IRQ_DELAY_STS_MASK       0xFF000000

//dma mm2s_length mask 14bit width
#define MM2S_LENGTH_MASK                0x7FFF

//dma s2mm_dmacr offset
#define S2MM_DMACR_RS_OFS               0
#define S2MM_DMACR_RESET_OFS            2
#define S2MM_DMACR_KEYHOLE_OFS          3
#define S2MM_DMACR_CYCLIC_BD_EN_OFS     4
#define S2MM_DMACR_IOC_IRQ_EN_OFS       12
#define S2MM_DMACR_DLY_IRQ_EN_OFS       13
#define S2MM_DMACR_ERR_IRQ_EN_OFS       14


//dma s2mm_dmacr mask
#define S2MM_DMACR_RS_MASK              (1<<S2MM_DMACR_RS_OFS)
#define S2MM_DMACR_RESET_MASK           (1<<S2MM_DMACR_RESET_OFS)
#define S2MM_DMACR_KEYHOLE_MASK         (1<<S2MM_DMACR_KEYHOLE_OFS)
#define S2MM_DMACR_CYCLIC_BD_EN_MASK    (1<<S2MM_DMACR_CYCLIC_BD_EN_OFS)
#define S2MM_DMACR_IOC_IRQ_EN_MASK      (1<<S2MM_DMACR_IOC_IRQ_EN_OFS)
#define S2MM_DMACR_DLY_IRQ_EN_MASK      (1<<S2MM_DMACR_DLY_IRQ_EN_OFS)
#define S2MM_DMACR_ERR_IRQ_EN_MASK      (1<<S2MM_DMACR_ERR_IRQ_EN_OFS)
#define S2MM_DMACR_IRQ_THRESHOLD_MASK   0xFF0000
#define S2MM_DMACR_IRQ_DELAY_MASK       0xFF00000000

//dma s2mm_dmasr offset
#define S2MM_DMASR_HALTED_OFS           0
#define S2MM_DMASR_IDLE_OFS             1
#define S2MM_DMASR_SGINCLD_OFS          3
#define S2MM_DMASR_DMA_INT_ERR_OFS      4
#define S2MM_DMASR_DMA_SLV_ERR_OFS      5
#define S2MM_DMASR_DMA_DEC_ERR_OFS      6
#define S2MM_DMASR_SG_INT_ERR_OFS       8
#define S2MM_DMASR_SG_SLV_ERR_OFS       9
#define S2MM_DMASR_SG_DEC_ERR_OFS       10
#define S2MM_DMASR_IOC_IRQ_OFS          12
#define S2MM_DMASR_DLY_IRQ_OFS          13
#define S2MM_DMASR_ERR_IRQ_OFS          14

//dma s2mm_dmasr mask
#define S2MM_DMASR_HALTED_MASK              (1<<S2MM_DMASR_HALTED_OFS)
#define S2MM_DMASR_IDLE_MASK                (1<<S2MM_DMASR_IDLE_OFS)
#define S2MM_DMASR_SGINCLD_MASK             (1<<S2MM_DMASR_SGINCLD_OFS)
#define S2MM_DMASR_DMA_INT_ERR_MASK         (1<<S2MM_DMASR_DMA_INT_ERR_OFS)
#define S2MM_DMASR_DMA_SLV_ERR_MASK         (1<<S2MM_DMASR_DMA_SLV_ERR_OFS)
#define S2MM_DMASR_DMA_DEC_ERR_MASK         (1<<S2MM_DMASR_DMA_DEC_ERR_OFS)
#define S2MM_DMASR_SG_INT_ERR_MASK          (1<<S2MM_DMASR_SG_INT_ERR_OFS)
#define S2MM_DMASR_SG_SLV_ERR_MASK          (1<<S2MM_DMASR_SG_SLV_ERR_OFS)
#define S2MM_DMASR_SG_DEC_ERR_MASK          (1<<S2MM_DMASR_SG_DEC_ERR_OFS)
#define S2MM_DMASR_IOC_IRQ_MASK             (1<<S2MM_DMASR_IOC_IRQ_OFS)
#define S2MM_DMASR_DLY_IRQ_MASK             (1<<S2MM_DMASR_DLY_IRQ_OFS)
#define S2MM_DMASR_ERR_IRQ_MASK             (1<<S2MM_DMASR_ERR_IRQ_OFS)
#define S2MM_DMASR_IRQ_THRESHOLD_STS_MASK   0xFF0000
#define S2MM_DMASR_IRQ_DELAY_STS_MASK       0xFF000000

//dma s2mm_length mask 14bit width
#define S2MM_LENGTH_MASK                0x7FFF

#define CLEAR_ALL_DMACR_MASK            0x00010002
#define CLEAR_ALL_DMASR_MASK            0x00010001
#define SET_ALL_IRQ                     0x00007000

// mm2s
inline void dma_set_mm2s_dmacr(volatile uint64_t *dma, uint32_t mask, uint32_t value);
inline void dma_clear_mm2s_dmacr(volatile uint64_t *dma);
inline int32_t dma_get_mm2s_dmacr(volatile uint64_t *dma);
inline void dma_set_mm2s_dmasr_irq(volatile uint64_t *dma, uint32_t mask);
inline int32_t dma_get_mm2s_dmasr_irq(volatile uint64_t *dma);
inline int32_t dma_get_mm2s_status(volatile uint64_t *dma);
inline void dma_set_mm2s_sa_lsb(volatile uint64_t *dma, uint32_t lsb);
inline void dma_set_mm2s_sa_msb(volatile uint64_t *dma, uint32_t msb);
inline void dma_set_mm2s_length(volatile uint64_t *dma, uint32_t length);

// s2mm
inline void dma_set_s2mm_dmacr(volatile uint64_t *dma, uint32_t mask, uint32_t value);
inline void dma_clear_s2mm_dmacr(volatile uint64_t *dma);
inline int32_t dma_get_s2mm_dmacr(volatile uint64_t *dma);
inline void dma_set_s2mm_dmasr_irq(volatile uint64_t *dma, uint32_t mask);
inline int32_t dma_get_s2mm_dmasr_irq(volatile uint64_t *dma);
inline int32_t dma_get_s2mm_status(volatile uint64_t *dma);
inline void dma_set_s2mm_da_lsb(volatile uint64_t *dma, uint32_t lab);
inline void dma_set_s2mm_da_msb(volatile uint64_t *dma, uint32_t msb);
inline void dma_set_s2mm_length(volatile uint64_t *dma, uint32_t length);

// debug
inline int32_t dma_get_s2mm_lsb(volatile uint64_t *dma);
inline int32_t dma_get_s2mm_length(volatile uint64_t *dma);
inline int32_t dma_get_mm2s_lsb(volatile uint64_t *dma);
inline int32_t dma_get_mm2s_length(volatile uint64_t *dma);

int memory_overlap();



#endif
