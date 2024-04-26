#include <stdio.h>
#include <stdlib.h>
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "polybench.h"
#include "polybench_cgra.h"
#include "cgra.h"
#include "gpio.h"
#include "pad_control.h"
#include "pad_control_regs.h"

volatile DATA_TYPE __attribute__((section(".data_interleaved"))) C[GEMM_NI * GEMM_NJ];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) A[GEMM_NI * GEMM_NK];
volatile DATA_TYPE __attribute__((section(".data_interleaved"))) B[GEMM_NK * GEMM_NJ];

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

void gemm_init_array(
    DATA_TYPE *A,
    DATA_TYPE *B,
    DATA_TYPE *C)
{
    int i, j;
    for (i = 0; i < GEMM_NI; i++) 
        for (j = 0; j < GEMM_NJ; j++) {
            C[i*GEMM_NJ+j] = 0; //(DATA_TYPE) i*GEMM_NJ+j;
        }
    for (i = 0; i < GEMM_NI; i++)
        for (j = 0; j < GEMM_NK; j++)
            A[i*GEMM_NK+j] = (DATA_TYPE) i*GEMM_NK+j;
    for (i = 0; i < GEMM_NK; i++)
        for (j = 0; j < GEMM_NJ; j++)
            B[i*GEMM_NJ+j] = (DATA_TYPE) i*GEMM_NJ+j;
}

int mm()
{

    gemm_init_array(A, B, C);

    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 0);

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
    mm_cgra(A, B, C);
    pinLow(PIN_TO_CTRL_VCD);

    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);

    int flag = 0;
    // for(int i = 0; i < GEMM_NI*GEMM_NJ; i++) 
    //     if(C_sw[i] != C[i]) flag++;

    return flag;
}
