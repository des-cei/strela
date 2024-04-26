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

#define SIZE 8 // 32
#define DATA_SIZE SIZE * SIZE
#define RESULT_SIZE (SIZE-2) * (SIZE-2)

#define ENABLE_PIN_TOGGLE 1
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

volatile int32_t image[DATA_SIZE];
volatile int32_t result[RESULT_SIZE];
volatile int32_t filter[9];

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
        image[i] = i;
    }

    filter[0] =  0;
    filter[1] = -1;
    filter[2] =  0;
    filter[3] = -1;
    filter[4] =  5;
    filter[5] = -1;
    filter[6] =  0;
    filter[7] = -1;
    filter[8] =  0;

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
    CSR_WRITE(CSR_REG_MCYCLE, 0);
    for(i = 1; i < SIZE - 1; i ++) {
        for(j = 1; j < SIZE - 1; j ++) {
            result[(i-1)*SIZE + j - 1] = filter[0]*image[(i-1)*SIZE + j - 1] + filter[1]*image[(i-1)*SIZE + j + 0] + filter[2]*image[(i-1)*SIZE + j + 1] + 
                                         filter[3]*image[(i+0)*SIZE + j - 1] + filter[4]*image[(i+0)*SIZE + j + 0] + filter[5]*image[(i+0)*SIZE + j + 1] + 
                                         filter[6]*image[(i+1)*SIZE + j - 1] + filter[7]*image[(i+1)*SIZE + j + 0] + filter[8]*image[(i+1)*SIZE + j + 1];
        }
    }
    CSR_READ(CSR_REG_MCYCLE, &sw_time);
    pinLow(PIN_TO_CTRL_VCD);
    
    printf("%lu\n", sw_time);
    return 0;
}
