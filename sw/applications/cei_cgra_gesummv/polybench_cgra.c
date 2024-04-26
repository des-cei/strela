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

void gemver_0(int n, DATA_TYPE *A, DATA_TYPE *u1, DATA_TYPE *v1, DATA_TYPE *u2, DATA_TYPE *v2)
{
    int iter2 = n / 2;
    int rem2 = n % 2;
    int row_ctr = 0;

    for(int i = 0; i < iter2; i++) {
        gemver_0_kernel[ 3]  = u1[row_ctr];
        gemver_0_kernel[ 8]  = u2[row_ctr+1];
        gemver_0_kernel[13]  = u1[row_ctr+1];
        gemver_0_kernel[18]  = u2[row_ctr];
        if(i == 0) {
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, gemver_0_kernel);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, GEMVER_0_BYTES);
        } else {
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 4UL);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, gemver_0_kernel);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, 80);
        }
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, &A[row_ctr*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, v1);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, v2);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_ADDR, &A[(row_ctr + 1)*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_ADDR, &A[row_ctr*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_SIZE, n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_ADDR, &A[(row_ctr + 1)*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_SIZE, n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
        // Wait CGRA is done
        overlay_intr_flag = 0;
        while(overlay_intr_flag == 0) wait_for_interrupt();

        row_ctr += 2;
    }
    if(rem2 != 0) {
        gemver_0_1_kernel[3]  = u1[row_ctr];
        gemver_0_1_kernel[8]  = u2[row_ctr];

        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 4UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, gemver_0_1_kernel);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, 80);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, &A[row_ctr*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, v1);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, v2);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_ADDR, &A[row_ctr*n]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_SIZE, n * sizeof(DATA_TYPE));
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
        // Wait CGRA is done
        overlay_intr_flag = 0;
        while(overlay_intr_flag == 0) wait_for_interrupt();
        
    }
}

void gemver_1_n3(int n, DATA_TYPE *A, DATA_TYPE *y, DATA_TYPE *x)
{
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, y);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[1]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_ADDR, &A[2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, x);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &x[1]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_ADDR, &x[2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    overlay_intr_flag = 0;
    while(overlay_intr_flag == 0) wait_for_interrupt();
}

void gemver_1_nn(int cols, int n, DATA_TYPE *A, DATA_TYPE *y, DATA_TYPE *x)
{
    switch(cols) {
        case 1:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, y);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, x);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            break;
        case 2:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, y);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[1]);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (n * sizeof(DATA_TYPE) << INSTR_SHIFT) | n * n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, x);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &x[1]);
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

void gemver_1(int n, DATA_TYPE *A, DATA_TYPE *y, DATA_TYPE *x)
{
    int i, col_ctr = 0;
    int iter3 = n / 3;
    int rem3 = n % 3;

    if(iter3 != 0) {
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, mult_cte_m_v_kernel);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, MULT_CTE_M_V_BYTES);

        
        for(i = 0; i < iter3; i++) {
            gemver_1_n3(n, &A[col_ctr], y, &x[col_ctr]);
            col_ctr += 3;
        }
    }

    if(rem3 != 0) {
        mult_cte_m_v_kernel[(4+rem3)*5] = 0xC0800010;
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 4UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, &mult_cte_m_v_kernel[(4+rem3)*5]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, 20);
        gemver_1_nn(rem3, n, &A[col_ctr], y, &x[col_ctr]);
        mult_cte_m_v_kernel[(4+rem3)*5] = 0xD0880010;
    }
}

void gemver_2(int n, DATA_TYPE *x, DATA_TYPE *z)
{
    int iter2 = n / 2;
    int rem2 = n % 2;

    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, gemver_2_kernel);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, GEMVER_2_BYTES);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, x);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | iter2 * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, z);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | iter2 * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &x[iter2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | (iter2 + rem2) * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_ADDR, &z[iter2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | (iter2 + rem2) * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_ADDR, x);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_SIZE, iter2 * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &x[iter2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, (iter2 + rem2) * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    overlay_intr_flag = 0;
    while(overlay_intr_flag == 0) wait_for_interrupt();
}

void gemver_3_n3(int n, DATA_TYPE *A, DATA_TYPE *x, DATA_TYPE *w)
{
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, x);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[n]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_ADDR, &A[2*n]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN3_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, w);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &w[1]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_ADDR, &w[2]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT3_SIZE, sizeof(DATA_TYPE));
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    overlay_intr_flag = 0;
    while(overlay_intr_flag == 0) wait_for_interrupt();
}

void gemver_3_nn(int cols, int n, DATA_TYPE *A, DATA_TYPE *x, DATA_TYPE *w)
{
    switch(cols) {
        case 1:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, x);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, w);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            break;
        case 2:
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, x);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_ADDR, A);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN1_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &A[n]);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, (sizeof(DATA_TYPE) << INSTR_SHIFT) | n * sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_ADDR, w);
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT1_SIZE, sizeof(DATA_TYPE));
            mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &w[1]);
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

void gemver_3(int n, DATA_TYPE *A, DATA_TYPE *x, DATA_TYPE *w)
{
    int i, row_ctr = 0;
    int iter3 = n / 3;
    int rem3 = n % 3;

    if(iter3 != 0) {
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, mult_cte_m_v_kernel);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, MULT_CTE_M_V_BYTES);

        for(i = 0; i < iter3; i++) {
            gemver_3_n3(n, &A[row_ctr*n], x, &w[row_ctr]);
            row_ctr += 3;
        }
    }

    if(rem3 != 0) {
        mult_cte_m_v_kernel[(4+rem3)*5] = 0xC0800010;
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 4UL);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, &mult_cte_m_v_kernel[(4+rem3)*5]);
        mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, 20);
        gemver_3_nn(rem3, n, &A[row_ctr*n], x, &w[row_ctr]);
        mult_cte_m_v_kernel[(4+rem3)*5] = 0xD0880010;
    }
}

void gesummv_cgra(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B, 
    DATA_TYPE *tmp,
    DATA_TYPE *x,
    DATA_TYPE *y)
{
    // tmp = alpha * A * x
    mult_cte_m_v_kernel[ 8] = *alpha;
    mult_cte_m_v_kernel[13] = *alpha;
    mult_cte_m_v_kernel[18] = *alpha;
    mult_cte_m_v_kernel[44] = (mult_cte_m_v_kernel[44] & 0xFFFF0000) | GESUMMV_N;
    mult_cte_m_v_kernel[49] = (mult_cte_m_v_kernel[49] & 0xFFFF0000) | GESUMMV_N;
    mult_cte_m_v_kernel[54] = (mult_cte_m_v_kernel[54] & 0xFFFF0000) | GESUMMV_N;
    gemver_3(GESUMMV_N, A, x, tmp);

    // y = beta * B * x
    mult_cte_m_v_kernel[ 8] = *beta;
    mult_cte_m_v_kernel[13] = *beta;
    mult_cte_m_v_kernel[18] = *beta;
    gemver_3(GESUMMV_N, B, x, y);

    // y = y + tmp
    gemver_2(GESUMMV_N, y, tmp);
}
