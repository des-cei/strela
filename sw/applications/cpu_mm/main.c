#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "core_v_mini_mcu.h"
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "gpio.h"

#define GEMM_NI 64
#define GEMM_NJ 64
#define GEMM_NK 64

#define ENABLE_PIN_TOGGLE 0
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

volatile int32_t A[GEMM_NI*GEMM_NK];
volatile int32_t B[GEMM_NK*GEMM_NJ];
volatile int32_t C[GEMM_NI*GEMM_NJ];

// -------------------- Waveform -------------------- //
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
    if (gpio_res != GpioOk) return 1;
    pin_cfg.pin = PIN_TO_CTRL_VCD;
    gpio_res = gpio_config(pin_cfg);
    if (gpio_res != GpioOk) return 1;
#endif
}

void newVCDfile()
{
#if ENABLE_PIN_TOGGLE
    pinHigh(PIN_TO_NEW_VCD);
    pinLow(PIN_TO_NEW_VCD);
#endif
}
// -------------------- Waveform -------------------- //

int main()
{
    // Hardware setup
    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);
    pinInit();
    CSR_WRITE(CSR_REG_MCOUNTINHIBIT, 0);

    int i, j, k;
    uint32_t sw_time;

    for (i = 0; i < GEMM_NI; i++)
        for (j = 0; j < GEMM_NK; j++)
            A[i*GEMM_NK+j] = (int32_t) i*GEMM_NK+j;
    for (i = 0; i < GEMM_NK; i++)
        for (j = 0; j < GEMM_NJ; j++)
            B[i*GEMM_NJ+j] = (int32_t) i*GEMM_NJ+j;

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    for (i = 0; i < GEMM_NI; i++) {
        for (k = 0; k < GEMM_NK; k++) {
            for (j = 0; j < GEMM_NJ; j++)
                C[i*GEMM_NJ+j] += A[i*GEMM_NK+k] * B[k*GEMM_NJ+j];
        }
    }
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);
    
    printf("%lu\n", sw_time);
    return 0;
}
