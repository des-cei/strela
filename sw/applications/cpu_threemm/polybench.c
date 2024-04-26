#include <stdio.h>
#include <stdlib.h>
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "polybench.h"
#include "polybench_cpu.h"
#include "cgra.h"
#include "gpio.h"
#include "pad_control.h"
#include "pad_control_regs.h"

volatile DATA_TYPE __attribute__((section(".data_interleaved"))) A[THREEMM_NI * THREEMM_NK];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) B[THREEMM_NK * THREEMM_NJ];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) C[THREEMM_NJ * THREEMM_NM];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) D[THREEMM_NM * THREEMM_NL];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) E[THREEMM_NI * THREEMM_NJ];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) F[THREEMM_NJ * THREEMM_NL];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) G[THREEMM_NI * THREEMM_NL];

extern mmio_region_t cgra;

inline __attribute__((always_inline)) void pinHigh( uint8_t pin )
{
#if ENABLE_PIN_TOGGLE
    gpio_write(pin, true);
#endif
}

inline __attribute__((always_inline)) void pinLow( uint8_t pin )
{
#if ENABLE_PIN_TOGGLE
    gpio_write(pin, false);
#endif
}

void pinInit()
{
#if ENABLE_PIN_TOGGLE
    // GPIO
    gpio_result_t gpio_res;
    gpio_cfg_t pin_cfg = {
        .pin = PIN_TO_NEW_VCD,
        .mode = GpioModeOutPushPull
    };
    gpio_res = gpio_config(pin_cfg);
    if (gpio_res != GpioOk)
        printf("Gpio initialization failed!\n");
    pin_cfg.pin = PIN_TO_CTRL_VCD;
    gpio_res = gpio_config(pin_cfg);
    if (gpio_res != GpioOk)
        printf("Gpio initialization failed!\n");
#endif
}

void newVCDfile()
{
#if ENABLE_PIN_TOGGLE
    pinHigh(PIN_TO_NEW_VCD);
    pinLow(PIN_TO_NEW_VCD);
#endif
}

void threemm_init_array(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D)
{
    int i, j;

    for (i = 0; i < THREEMM_NI; i++)
        for (j = 0; j < THREEMM_NK; j++)
            A[i*THREEMM_NK+j] = i*THREEMM_NK+j;
    for (i = 0; i < THREEMM_NK; i++)
        for (j = 0; j < THREEMM_NJ; j++)
            B[i*THREEMM_NJ+j] = i*THREEMM_NJ+j;
    for (i = 0; i < THREEMM_NJ; i++)
        for (j = 0; j < THREEMM_NM; j++)
            C[i*THREEMM_NM+j] = i*THREEMM_NM+j;
    for (i = 0; i < THREEMM_NM; i++)
        for (j = 0; j < THREEMM_NL; j++)
            D[i*THREEMM_NL+j] = i*THREEMM_NL+j;
}

int gemm()
{
    uint32_t sw_time;

    threemm_init_array(A, B, C, D);

    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);
    CSR_WRITE(CSR_REG_MCOUNTINHIBIT, 0);

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    threemm_cpu(A, B, C, D, E, F, G);
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);

    printf("%lu\n", sw_time);
    return 0;
}
