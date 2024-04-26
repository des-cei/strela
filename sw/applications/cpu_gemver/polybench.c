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

volatile DATA_TYPE __attribute__((section(".data_interleaved"))) A[GEMVER_N * GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) u1[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) v1[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) u2[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) v2[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) w[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) x[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) y[GEMVER_N];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) z[GEMVER_N];

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

void gemver_init_array(
    DATA_TYPE *alpha, 
    DATA_TYPE *beta,
    DATA_TYPE *A,
    DATA_TYPE *u1,
    DATA_TYPE *v1,
    DATA_TYPE *u2,
    DATA_TYPE *v2,
    DATA_TYPE *w,
    DATA_TYPE *x,
    DATA_TYPE *y,
    DATA_TYPE *z)
{
    int i, j;

    *alpha = 3;
    *beta = 2;

    for (i = 0; i < GEMVER_N; i++) {
        u1[i] = i+0;
        v1[i] = i+1;
        u2[i] = i+2;
        v2[i] = i+3;
        y[i] = i+4;
        z[i] = i+5;
        x[i] = 0;
        w[i] = 0;
        for (j = 0; j < GEMVER_N; j++)
            A[i*GEMVER_N+j] = i*GEMVER_N+j;
    }
}

int gemm()
{
    DATA_TYPE alpha;
    DATA_TYPE beta;
    uint32_t sw_time;

    gemver_init_array(&alpha, &beta, A, u1, v1, u2, v2, w, x, y, z);

    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);
    CSR_WRITE(CSR_REG_MCOUNTINHIBIT, 0);

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    gemver_cpu(&alpha, &beta, A, u1, v1, u2, v2, w, x, y, z);
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);

    printf("%lu\n", sw_time);
    return 0;
}
