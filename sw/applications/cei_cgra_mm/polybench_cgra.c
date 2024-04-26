#include <stdlib.h>
#include "core_v_mini_mcu.h"
#include "hart.h"
#include "handler.h"
#include "fast_intr_ctrl.h"
#include "fast_intr_ctrl_regs.h"
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "polybench_cgra.h"
#include "cgra.h"
#include "kernels.h"

mmio_region_t cgra;
volatile uint8_t overlay_intr_flag;

volatile DATA_TYPE __attribute__((section(".data_interleaved"))) M[GEMM_NI * GEMM_NJ];

void fic_irq_cgra(void) {
    overlay_intr_flag = 1;
}

void init_cgra()
{
    enable_all_fast_interrupts(true);
    // Enable interrupt on processor side
    // Enable global interrupt for machine-level interrupts
    CSR_SET_BITS(CSR_REG_MSTATUS, 0x8);
    // Set mie.MEIE bit to one to enable machine-level fast interrupts
    const uint32_t mask = 1 << 30;
    CSR_SET_BITS(CSR_REG_MIE, mask);

    // Hardware
    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 0);
    
    cgra = mmio_region_from_addr(CGRA_BASE_ADDR);
}

void mult_cte_3m_v_cgra(int j, int k, DATA_TYPE *A, DATA_TYPE *B, DATA_TYPE *C)
{
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, B);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (j * sizeof(DATA_TYPE) << INSTR_SHIFT) | j * k * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[k]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_ADDR, &A[2*k]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, C);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &C[j]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_ADDR, &C[2*j]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    overlay_intr_flag = 0;
    while(overlay_intr_flag == 0) wait_for_interrupt();
}

void mult_cte_nm_v_cgra(int cols, int j, int k, DATA_TYPE *A, DATA_TYPE *B, DATA_TYPE *C)
{
    switch(cols) {
        case 1:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, B);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (j * sizeof(DATA_TYPE) << INSTR_SHIFT) | j * k * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, C);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            break;
        case 2:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, B);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (j * sizeof(DATA_TYPE) << INSTR_SHIFT) | j * k * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[k]);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | k * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, C);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &C[j]);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, sizeof(DATA_TYPE));
            break;
        default:
            break;
    }
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    overlay_intr_flag = 0;
    while(overlay_intr_flag == 0) wait_for_interrupt();
}

void matmul(int n, int m, int t, DATA_TYPE *A, DATA_TYPE *B, DATA_TYPE *C)
{
    int i, j, row_ctr = 0;
    int iter3 = n / 3;
    int rem3 = n % 3;

    if(iter3 != 0) {
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, dot_product_kernel);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, DOT_PRODUCT_BYTES);

        for(j = 0; j < m; j++) {
            row_ctr = 0;
            for(i = 0; i < iter3; i++) {
                mult_cte_3m_v_cgra(m, t, 
                    &A[row_ctr*t],
                    &B[j],
                    &C[row_ctr*m+j]);
                row_ctr += 3;
            }
        }
    }

    if(rem3 != 0) {
        dot_product_kernel[rem3*5] = 0xC0800010;
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 4UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, &dot_product_kernel[rem3*5]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, 20);
        for(j = 0; j < m; j++)
            mult_cte_nm_v_cgra(rem3, m, t, 
                &A[row_ctr*t],
                &B[j],
                &C[row_ctr*m+j]);
        dot_product_kernel[rem3*5] = 0xD0880010;
    }
}
void mm_cgra(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C)
{
    // C = A * B
    dot_product_kernel[24] = (dot_product_kernel[24] & 0xFFFF0000) | GEMM_NK;
    dot_product_kernel[29] = (dot_product_kernel[29] & 0xFFFF0000) | GEMM_NK;
    dot_product_kernel[34] = (dot_product_kernel[34] & 0xFFFF0000) | GEMM_NK;

    matmul(GEMM_NI, GEMM_NJ, GEMM_NK, A, B, C);
}
