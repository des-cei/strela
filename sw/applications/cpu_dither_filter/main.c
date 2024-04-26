#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#include "core_v_mini_mcu.h"
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "gpio.h"

#define SIZE 8 //32
#define DATA_SIZE SIZE * SIZE

#define ENABLE_PIN_TOGGLE 1
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

volatile int32_t image[DATA_SIZE];
volatile int32_t result[DATA_SIZE];

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

    int i, j;
    uint32_t sw_time;

    for(i = 0; i < DATA_SIZE; i ++) {
        if(i%2 == 0) image[i] = i;
        else image[i] = -i;
    }
    int32_t err = 0, out = 0, pixel;

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
#if !ENABLE_PIN_TOGGLE
    CSR_WRITE(CSR_REG_MCYCLE, 0);
#endif
    for(i = 0; i < DATA_SIZE; i ++) {
        out = image[i] + err;
        if(out > 0) {
            pixel = 0xFF;
            err = out - pixel;
        }
        else {
            pixel = 0;
            err = out;
        }
        result[i] = pixel;
    }
#if !ENABLE_PIN_TOGGLE
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
#endif
    pinLow(PIN_TO_CTRL_VCD);
    
    printf("%lu\n", sw_time);
    return 0;
}
