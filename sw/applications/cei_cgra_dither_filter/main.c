#include <stdio.h>
#include <stdint.h>
#include "core_v_mini_mcu.h"
#include "csr.h"
#include "csr_registers.h"
#include "mmio.h"
#include "hart.h"
#include "handler.h"
#include "fast_intr_ctrl.h"
#include "fast_intr_ctrl_regs.h"
#include "heepocrates.h"
#include "heepocrates_ctrl.h"
#include "cgra.h"
#include "kernels.h"
#include "gpio.h"
#include "dataset.h"

#define ENABLE_PIN_TOGGLE 1
#define PIN_TO_CTRL_VCD 6
#define PIN_TO_NEW_VCD 7

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

// -------------------- CGRA -------------------- //
mmio_region_t cgra;
volatile uint8_t cgra_intr_flag;

void fic_irq_cgra(void) {
    cgra_intr_flag = 1;
}
// -------------------- CGRA -------------------- //


int main(int argc, char *argv[])
{
    enable_all_fast_interrupts(true);
    // Enable interrupt on processor side
    // Enable global interrupt for machine-level interrupts
    CSR_SET_BITS(CSR_REG_MSTATUS, 0x8);
    // Set mie.MEIE bit to one to enable machine-level fast interrupts
    const uint32_t mask = 1 << 30;
    CSR_SET_BITS(CSR_REG_MIE, mask);

    // Hardware setup
    heepocrates_ctrl_t heepocrates_ctrl;
    heepocrates_ctrl.base_addr = mmio_region_from_addr((uintptr_t)HEEPOCRATES_CTRL_START_ADDRESS);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);

    pinInit();

    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 0);
    cgra = mmio_region_from_addr(CGRA_BASE_ADDR);
    int chunk = DATA_SIZE / 2;
    int rest = DATA_SIZE % 2;
    uint32_t in1_param = (sizeof(int32_t) << 16) | chunk * sizeof(int32_t);
    uint32_t out1_param = chunk * sizeof(int32_t);
    uint32_t in2_param = (sizeof(int32_t) << 16) | (chunk+rest) * sizeof(int32_t);
    uint32_t out2_param = (chunk+rest) * sizeof(int32_t);

    newVCDfile();
    pinHigh(PIN_TO_CTRL_VCD);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 2UL);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_ADDR, dither_filter_kernel);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_BS_SIZE, DITHER_FILTER_KRNL_BYTES);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_ADDR, image);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN0_SS, in1_param);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_ADDR, &image[chunk]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_IN2_SS, in2_param);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_ADDR, result);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT0_SIZE, out1_param);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_ADDR, &result[chunk]);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_OUT2_SIZE, out2_param);
    mmio_region_write32(cgra, (ptrdiff_t) CGRA_CONF, 1UL);
    // Wait CGRA is done
    cgra_intr_flag = 0;
    while(cgra_intr_flag == 0) wait_for_interrupt();
    pinLow(PIN_TO_CTRL_VCD);
    heepocrates_ctrl_cgra_disable(&heepocrates_ctrl, 1);

    int flag = 0;
    // for(i = 0; i < SIZE; i++) {
    // }
    // if(flag ==0) printf("SUCCESS\n");
    // else printf("FAIL\n");
    return flag;
}