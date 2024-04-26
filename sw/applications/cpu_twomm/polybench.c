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

volatile DATA_TYPE __attribute__((section(".data_interleaved"))) tmp[TWOMM_NI * TWOMM_NJ];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) A[TWOMM_NI * TWOMM_NK];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) B[TWOMM_NK * TWOMM_NJ];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) C[TWOMM_NJ * TWOMM_NL];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) D[TWOMM_NI * TWOMM_NL];

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

void twomm_init_array(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C,
    DATA_TYPE *D)
{
    int i, j;

    *alpha = 3;
    *beta = 2;
    for (i = 0; i < TWOMM_NI; i++)
        for (j = 0; j < TWOMM_NK; j++)
            A[i*TWOMM_NK+j] = i*TWOMM_NK+j;
    for (i = 0; i < TWOMM_NK; i++)
        for (j = 0; j < TWOMM_NJ; j++)
            B[i*TWOMM_NJ+j] = i*TWOMM_NJ+j;
    for (i = 0; i < TWOMM_NJ; i++)
        for (j = 0; j < TWOMM_NL; j++)
            C[i*TWOMM_NL+j] = i*TWOMM_NL+j;
    for (i = 0; i < TWOMM_NI; i++)
        for (j = 0; j < TWOMM_NL; j++)
            D[i*TWOMM_NL+j] = i*TWOMM_NL+j;
}

int gemm()
{
    DATA_TYPE alpha;
    DATA_TYPE beta;
    uint32_t sw_time;

    twomm_init_array(&alpha, &beta, A, B, C, D);

    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);
    CSR_WRITE(CSR_REG_MCOUNTINHIBIT, 0);

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    twomm_cpu(&alpha, &beta, tmp, A, B, C, D);
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);

    printf("%lu\n", sw_time);
    return 0;
}
