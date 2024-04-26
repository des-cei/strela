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

#define DATA_SIZE 16 // 256

#define ENABLE_PIN_TOGGLE 1
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

volatile int32_t real_l[DATA_SIZE];
volatile int32_t real_h[DATA_SIZE];
volatile int32_t imag_l[DATA_SIZE];
volatile int32_t imag_h[DATA_SIZE];

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

    int i;
    uint32_t sw_time;

    int32_t tmp_real, tmp_imag;

    for(i = 0; i < DATA_SIZE; i ++) {
        real_l[i] = i;
        real_h[i] = 2*i;
        imag_l[i] = -i;
        imag_h[i] = -2*i;
    }

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    for(i = 0; i < DATA_SIZE; i ++) {
        tmp_real = 7*real_h[i] - 6*imag_h[i];
        tmp_imag = 6*real_h[i] + 7*imag_h[i];
        real_h[i] = real_l[i] - tmp_real;
        real_l[i] += tmp_real;
        imag_h[i] = imag_l[i] - tmp_imag;
        imag_l[i] += tmp_imag;
    }
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);
    
    printf("%lu\n", sw_time);
    return 0;
}
