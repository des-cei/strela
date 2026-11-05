// Generated register defines for strela

// Copyright information found in source file:
// Copyright 2026 CEIMM-UPM

// Licensing information found in source file:
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#ifndef _STRELA_REG_DEFS_
#define _STRELA_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define STRELA_PARAM_REG_WIDTH 32

// STRELA control register
#define STRELA_CTRL_REG_OFFSET 0x0
#define STRELA_CTRL_START_BIT 0
#define STRELA_CTRL_CLR_BIT 1
#define STRELA_CTRL_CLR_PARAM_BIT 2
#define STRELA_CTRL_CLR_CONF_BIT 3
#define STRELA_CTRL_CLR_PERF_CTR_BIT 4

// STRELA mode register
#define STRELA_MODE_REG_OFFSET 0x4
#define STRELA_MODE_INTR_EN_BIT 0
#define STRELA_MODE_PERF_CTR_EN_BIT 1

// STRELA status register
#define STRELA_STATUS_REG_OFFSET 0x8
#define STRELA_STATUS_EXEC_DONE_BIT 0
#define STRELA_STATUS_CONF_DONE_BIT 1

// STRELA performance counter: total cycles
#define STRELA_PERF_CTR_TOTAL_CYCLES_REG_OFFSET 0xc

// STRELA performance counter: execution cycles
#define STRELA_PERF_CTR_EXEC_CYCLES_REG_OFFSET 0x10

// STRELA performance counter: configuration cycles
#define STRELA_PERF_CTR_CONF_CYCLES_REG_OFFSET 0x14

// STRELA performance counter: stall cycles
#define STRELA_PERF_CTR_STALL_CYCLES_REG_OFFSET 0x18

// STRELA configuration address register
#define STRELA_CONF_ADDR_REG_OFFSET 0x1c

// STRELA Input Stream Engines selected element width. One 3-bit field per
// engine, bits [3i+2:3i]; bits 23:12 are reserved for engines 4-7
#define STRELA_ISE_SEW_REG_OFFSET 0x20
#define STRELA_ISE_SEW_ISE_0_SEW_MASK 0x7
#define STRELA_ISE_SEW_ISE_0_SEW_OFFSET 0
#define STRELA_ISE_SEW_ISE_0_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_SEW_ISE_0_SEW_MASK, .index = STRELA_ISE_SEW_ISE_0_SEW_OFFSET })
#define STRELA_ISE_SEW_ISE_1_SEW_MASK 0x7
#define STRELA_ISE_SEW_ISE_1_SEW_OFFSET 3
#define STRELA_ISE_SEW_ISE_1_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_SEW_ISE_1_SEW_MASK, .index = STRELA_ISE_SEW_ISE_1_SEW_OFFSET })
#define STRELA_ISE_SEW_ISE_2_SEW_MASK 0x7
#define STRELA_ISE_SEW_ISE_2_SEW_OFFSET 6
#define STRELA_ISE_SEW_ISE_2_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_SEW_ISE_2_SEW_MASK, .index = STRELA_ISE_SEW_ISE_2_SEW_OFFSET })
#define STRELA_ISE_SEW_ISE_3_SEW_MASK 0x7
#define STRELA_ISE_SEW_ISE_3_SEW_OFFSET 9
#define STRELA_ISE_SEW_ISE_3_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_SEW_ISE_3_SEW_MASK, .index = STRELA_ISE_SEW_ISE_3_SEW_OFFSET })

// STRELA Output Stream Engines selected element width. One 3-bit field per
// engine, bits [3i+2:3i]; bits 23:12 are reserved for engines 4-7
#define STRELA_OSE_SEW_REG_OFFSET 0x24
#define STRELA_OSE_SEW_OSE_0_SEW_MASK 0x7
#define STRELA_OSE_SEW_OSE_0_SEW_OFFSET 0
#define STRELA_OSE_SEW_OSE_0_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_SEW_OSE_0_SEW_MASK, .index = STRELA_OSE_SEW_OSE_0_SEW_OFFSET })
#define STRELA_OSE_SEW_OSE_1_SEW_MASK 0x7
#define STRELA_OSE_SEW_OSE_1_SEW_OFFSET 3
#define STRELA_OSE_SEW_OSE_1_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_SEW_OSE_1_SEW_MASK, .index = STRELA_OSE_SEW_OSE_1_SEW_OFFSET })
#define STRELA_OSE_SEW_OSE_2_SEW_MASK 0x7
#define STRELA_OSE_SEW_OSE_2_SEW_OFFSET 6
#define STRELA_OSE_SEW_OSE_2_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_SEW_OSE_2_SEW_MASK, .index = STRELA_OSE_SEW_OSE_2_SEW_OFFSET })
#define STRELA_OSE_SEW_OSE_3_SEW_MASK 0x7
#define STRELA_OSE_SEW_OSE_3_SEW_OFFSET 9
#define STRELA_OSE_SEW_OSE_3_SEW_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_SEW_OSE_3_SEW_MASK, .index = STRELA_OSE_SEW_OSE_3_SEW_OFFSET })

// STRELA Input Stream Engine 0 address register
#define STRELA_ISE_0_ADDR_REG_OFFSET 0x28

// STRELA Input Stream Engine 0 size and stride register
#define STRELA_ISE_0_PARAM_REG_OFFSET 0x2c
#define STRELA_ISE_0_PARAM_ISE_0_SIZE_MASK 0xffff
#define STRELA_ISE_0_PARAM_ISE_0_SIZE_OFFSET 0
#define STRELA_ISE_0_PARAM_ISE_0_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_0_PARAM_ISE_0_SIZE_MASK, .index = STRELA_ISE_0_PARAM_ISE_0_SIZE_OFFSET })
#define STRELA_ISE_0_PARAM_ISE_0_STRIDE_MASK 0xffff
#define STRELA_ISE_0_PARAM_ISE_0_STRIDE_OFFSET 16
#define STRELA_ISE_0_PARAM_ISE_0_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_0_PARAM_ISE_0_STRIDE_MASK, .index = STRELA_ISE_0_PARAM_ISE_0_STRIDE_OFFSET })

// STRELA Input Stream Engine 1 address register
#define STRELA_ISE_1_ADDR_REG_OFFSET 0x30

// STRELA Input Stream Engine 1 size and stride register
#define STRELA_ISE_1_PARAM_REG_OFFSET 0x34
#define STRELA_ISE_1_PARAM_ISE_1_SIZE_MASK 0xffff
#define STRELA_ISE_1_PARAM_ISE_1_SIZE_OFFSET 0
#define STRELA_ISE_1_PARAM_ISE_1_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_1_PARAM_ISE_1_SIZE_MASK, .index = STRELA_ISE_1_PARAM_ISE_1_SIZE_OFFSET })
#define STRELA_ISE_1_PARAM_ISE_1_STRIDE_MASK 0xffff
#define STRELA_ISE_1_PARAM_ISE_1_STRIDE_OFFSET 16
#define STRELA_ISE_1_PARAM_ISE_1_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_1_PARAM_ISE_1_STRIDE_MASK, .index = STRELA_ISE_1_PARAM_ISE_1_STRIDE_OFFSET })

// STRELA Input Stream Engine 2 address register
#define STRELA_ISE_2_ADDR_REG_OFFSET 0x38

// STRELA Input Stream Engine 2 size and stride register
#define STRELA_ISE_2_PARAM_REG_OFFSET 0x3c
#define STRELA_ISE_2_PARAM_ISE_2_SIZE_MASK 0xffff
#define STRELA_ISE_2_PARAM_ISE_2_SIZE_OFFSET 0
#define STRELA_ISE_2_PARAM_ISE_2_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_2_PARAM_ISE_2_SIZE_MASK, .index = STRELA_ISE_2_PARAM_ISE_2_SIZE_OFFSET })
#define STRELA_ISE_2_PARAM_ISE_2_STRIDE_MASK 0xffff
#define STRELA_ISE_2_PARAM_ISE_2_STRIDE_OFFSET 16
#define STRELA_ISE_2_PARAM_ISE_2_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_2_PARAM_ISE_2_STRIDE_MASK, .index = STRELA_ISE_2_PARAM_ISE_2_STRIDE_OFFSET })

// STRELA Input Stream Engine 3 address register
#define STRELA_ISE_3_ADDR_REG_OFFSET 0x40

// STRELA Input Stream Engine 3 size and stride register
#define STRELA_ISE_3_PARAM_REG_OFFSET 0x44
#define STRELA_ISE_3_PARAM_ISE_3_SIZE_MASK 0xffff
#define STRELA_ISE_3_PARAM_ISE_3_SIZE_OFFSET 0
#define STRELA_ISE_3_PARAM_ISE_3_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_3_PARAM_ISE_3_SIZE_MASK, .index = STRELA_ISE_3_PARAM_ISE_3_SIZE_OFFSET })
#define STRELA_ISE_3_PARAM_ISE_3_STRIDE_MASK 0xffff
#define STRELA_ISE_3_PARAM_ISE_3_STRIDE_OFFSET 16
#define STRELA_ISE_3_PARAM_ISE_3_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_ISE_3_PARAM_ISE_3_STRIDE_MASK, .index = STRELA_ISE_3_PARAM_ISE_3_STRIDE_OFFSET })

// STRELA Output Stream Engine 0 address register
#define STRELA_OSE_0_ADDR_REG_OFFSET 0x48

// STRELA Output Stream Engine 0 size and stride register
#define STRELA_OSE_0_PARAM_REG_OFFSET 0x4c
#define STRELA_OSE_0_PARAM_OSE_0_SIZE_MASK 0xffff
#define STRELA_OSE_0_PARAM_OSE_0_SIZE_OFFSET 0
#define STRELA_OSE_0_PARAM_OSE_0_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_0_PARAM_OSE_0_SIZE_MASK, .index = STRELA_OSE_0_PARAM_OSE_0_SIZE_OFFSET })
#define STRELA_OSE_0_PARAM_OSE_0_STRIDE_MASK 0xffff
#define STRELA_OSE_0_PARAM_OSE_0_STRIDE_OFFSET 16
#define STRELA_OSE_0_PARAM_OSE_0_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_0_PARAM_OSE_0_STRIDE_MASK, .index = STRELA_OSE_0_PARAM_OSE_0_STRIDE_OFFSET })

// STRELA Output Stream Engine 1 address register
#define STRELA_OSE_1_ADDR_REG_OFFSET 0x50

// STRELA Output Stream Engine 1 size and stride register
#define STRELA_OSE_1_PARAM_REG_OFFSET 0x54
#define STRELA_OSE_1_PARAM_OSE_1_SIZE_MASK 0xffff
#define STRELA_OSE_1_PARAM_OSE_1_SIZE_OFFSET 0
#define STRELA_OSE_1_PARAM_OSE_1_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_1_PARAM_OSE_1_SIZE_MASK, .index = STRELA_OSE_1_PARAM_OSE_1_SIZE_OFFSET })
#define STRELA_OSE_1_PARAM_OSE_1_STRIDE_MASK 0xffff
#define STRELA_OSE_1_PARAM_OSE_1_STRIDE_OFFSET 16
#define STRELA_OSE_1_PARAM_OSE_1_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_1_PARAM_OSE_1_STRIDE_MASK, .index = STRELA_OSE_1_PARAM_OSE_1_STRIDE_OFFSET })

// STRELA Output Stream Engine 2 address register
#define STRELA_OSE_2_ADDR_REG_OFFSET 0x58

// STRELA Output Stream Engine 2 size and stride register
#define STRELA_OSE_2_PARAM_REG_OFFSET 0x5c
#define STRELA_OSE_2_PARAM_OSE_2_SIZE_MASK 0xffff
#define STRELA_OSE_2_PARAM_OSE_2_SIZE_OFFSET 0
#define STRELA_OSE_2_PARAM_OSE_2_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_2_PARAM_OSE_2_SIZE_MASK, .index = STRELA_OSE_2_PARAM_OSE_2_SIZE_OFFSET })
#define STRELA_OSE_2_PARAM_OSE_2_STRIDE_MASK 0xffff
#define STRELA_OSE_2_PARAM_OSE_2_STRIDE_OFFSET 16
#define STRELA_OSE_2_PARAM_OSE_2_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_2_PARAM_OSE_2_STRIDE_MASK, .index = STRELA_OSE_2_PARAM_OSE_2_STRIDE_OFFSET })

// STRELA Output Stream Engine 3 address register
#define STRELA_OSE_3_ADDR_REG_OFFSET 0x60

// STRELA Output Stream Engine 3 size and stride register
#define STRELA_OSE_3_PARAM_REG_OFFSET 0x64
#define STRELA_OSE_3_PARAM_OSE_3_SIZE_MASK 0xffff
#define STRELA_OSE_3_PARAM_OSE_3_SIZE_OFFSET 0
#define STRELA_OSE_3_PARAM_OSE_3_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_3_PARAM_OSE_3_SIZE_MASK, .index = STRELA_OSE_3_PARAM_OSE_3_SIZE_OFFSET })
#define STRELA_OSE_3_PARAM_OSE_3_STRIDE_MASK 0xffff
#define STRELA_OSE_3_PARAM_OSE_3_STRIDE_OFFSET 16
#define STRELA_OSE_3_PARAM_OSE_3_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OSE_3_PARAM_OSE_3_STRIDE_MASK, .index = STRELA_OSE_3_PARAM_OSE_3_STRIDE_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _STRELA_REG_DEFS_
// End generated register defines for strela