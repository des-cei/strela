// Generated register defines for strela

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

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
#define STRELA_CTRL_CLR_PARAM_BIT 1
#define STRELA_CTRL_CLR_CONF_BIT 2
#define STRELA_CTRL_PERF_CTR_EN_BIT 3
#define STRELA_CTRL_PERF_CTR_RST_BIT 4

// STRELA status register
#define STRELA_STATUS_REG_OFFSET 0x4
#define STRELA_STATUS_EXEC_DONE_BIT 0
#define STRELA_STATUS_CONF_DONE_BIT 1

// STRELA performance counter: total cycles
#define STRELA_PERF_CTR_TOTAL_CYCLES_REG_OFFSET 0x8

// STRELA performance counter: execution cycles
#define STRELA_PERF_CTR_EXEC_CYCLES_REG_OFFSET 0xc

// STRELA performance counter: configuration cycles
#define STRELA_PERF_CTR_CONF_CYCLES_REG_OFFSET 0x10

// STRELA performance counter: stall cycles
#define STRELA_PERF_CTR_STALL_CYCLES_REG_OFFSET 0x14

// STRELA configuration address register
#define STRELA_CONF_ADDR_REG_OFFSET 0x18

// STRELA configuration size register
#define STRELA_CONF_SIZE_REG_OFFSET 0x1c
#define STRELA_CONF_SIZE_CONF_SIZE_MASK 0xffff
#define STRELA_CONF_SIZE_CONF_SIZE_OFFSET 0
#define STRELA_CONF_SIZE_CONF_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_CONF_SIZE_CONF_SIZE_MASK, .index = STRELA_CONF_SIZE_CONF_SIZE_OFFSET })

// STRELA Input Memory Node 0 address register
#define STRELA_IMN_0_ADDR_REG_OFFSET 0x20

// STRELA Input Memory Node 0 extra parameters register
#define STRELA_IMN_0_PARAM_REG_OFFSET 0x24
#define STRELA_IMN_0_PARAM_IMN_0_SIZE_MASK 0xffff
#define STRELA_IMN_0_PARAM_IMN_0_SIZE_OFFSET 0
#define STRELA_IMN_0_PARAM_IMN_0_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_0_PARAM_IMN_0_SIZE_MASK, .index = STRELA_IMN_0_PARAM_IMN_0_SIZE_OFFSET })
#define STRELA_IMN_0_PARAM_IMN_0_STRIDE_MASK 0xffff
#define STRELA_IMN_0_PARAM_IMN_0_STRIDE_OFFSET 16
#define STRELA_IMN_0_PARAM_IMN_0_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_0_PARAM_IMN_0_STRIDE_MASK, .index = STRELA_IMN_0_PARAM_IMN_0_STRIDE_OFFSET })

// STRELA Input Memory Node 1 address register
#define STRELA_IMN_1_ADDR_REG_OFFSET 0x28

// STRELA Input Memory Node 1 extra parameters register
#define STRELA_IMN_1_PARAM_REG_OFFSET 0x2c
#define STRELA_IMN_1_PARAM_IMN_1_SIZE_MASK 0xffff
#define STRELA_IMN_1_PARAM_IMN_1_SIZE_OFFSET 0
#define STRELA_IMN_1_PARAM_IMN_1_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_1_PARAM_IMN_1_SIZE_MASK, .index = STRELA_IMN_1_PARAM_IMN_1_SIZE_OFFSET })
#define STRELA_IMN_1_PARAM_IMN_1_STRIDE_MASK 0xffff
#define STRELA_IMN_1_PARAM_IMN_1_STRIDE_OFFSET 16
#define STRELA_IMN_1_PARAM_IMN_1_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_1_PARAM_IMN_1_STRIDE_MASK, .index = STRELA_IMN_1_PARAM_IMN_1_STRIDE_OFFSET })

// STRELA Input Memory Node 2 address register
#define STRELA_IMN_2_ADDR_REG_OFFSET 0x30

// STRELA Input Memory Node 2 extra parameters register
#define STRELA_IMN_2_PARAM_REG_OFFSET 0x34
#define STRELA_IMN_2_PARAM_IMN_2_SIZE_MASK 0xffff
#define STRELA_IMN_2_PARAM_IMN_2_SIZE_OFFSET 0
#define STRELA_IMN_2_PARAM_IMN_2_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_2_PARAM_IMN_2_SIZE_MASK, .index = STRELA_IMN_2_PARAM_IMN_2_SIZE_OFFSET })
#define STRELA_IMN_2_PARAM_IMN_2_STRIDE_MASK 0xffff
#define STRELA_IMN_2_PARAM_IMN_2_STRIDE_OFFSET 16
#define STRELA_IMN_2_PARAM_IMN_2_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_2_PARAM_IMN_2_STRIDE_MASK, .index = STRELA_IMN_2_PARAM_IMN_2_STRIDE_OFFSET })

// STRELA Input Memory Node 3 address register
#define STRELA_IMN_3_ADDR_REG_OFFSET 0x38

// STRELA Input Memory Node 3 extra parameters register
#define STRELA_IMN_3_PARAM_REG_OFFSET 0x3c
#define STRELA_IMN_3_PARAM_IMN_3_SIZE_MASK 0xffff
#define STRELA_IMN_3_PARAM_IMN_3_SIZE_OFFSET 0
#define STRELA_IMN_3_PARAM_IMN_3_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_3_PARAM_IMN_3_SIZE_MASK, .index = STRELA_IMN_3_PARAM_IMN_3_SIZE_OFFSET })
#define STRELA_IMN_3_PARAM_IMN_3_STRIDE_MASK 0xffff
#define STRELA_IMN_3_PARAM_IMN_3_STRIDE_OFFSET 16
#define STRELA_IMN_3_PARAM_IMN_3_STRIDE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_IMN_3_PARAM_IMN_3_STRIDE_MASK, .index = STRELA_IMN_3_PARAM_IMN_3_STRIDE_OFFSET })

// STRELA Output Memory Node 0 address register
#define STRELA_OMN_0_ADDR_REG_OFFSET 0x40

// STRELA Output Memory Node 0 size register
#define STRELA_OMN_0_SIZE_REG_OFFSET 0x44
#define STRELA_OMN_0_SIZE_OMN_0_SIZE_MASK 0xffff
#define STRELA_OMN_0_SIZE_OMN_0_SIZE_OFFSET 0
#define STRELA_OMN_0_SIZE_OMN_0_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OMN_0_SIZE_OMN_0_SIZE_MASK, .index = STRELA_OMN_0_SIZE_OMN_0_SIZE_OFFSET })

// STRELA Output Memory Node 1 address register
#define STRELA_OMN_1_ADDR_REG_OFFSET 0x48

// STRELA Output Memory Node 1 size register
#define STRELA_OMN_1_SIZE_REG_OFFSET 0x4c
#define STRELA_OMN_1_SIZE_OMN_1_SIZE_MASK 0xffff
#define STRELA_OMN_1_SIZE_OMN_1_SIZE_OFFSET 0
#define STRELA_OMN_1_SIZE_OMN_1_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OMN_1_SIZE_OMN_1_SIZE_MASK, .index = STRELA_OMN_1_SIZE_OMN_1_SIZE_OFFSET })

// STRELA Output Memory Node 2 address register
#define STRELA_OMN_2_ADDR_REG_OFFSET 0x50

// STRELA Output Memory Node 2 size register
#define STRELA_OMN_2_SIZE_REG_OFFSET 0x54
#define STRELA_OMN_2_SIZE_OMN_2_SIZE_MASK 0xffff
#define STRELA_OMN_2_SIZE_OMN_2_SIZE_OFFSET 0
#define STRELA_OMN_2_SIZE_OMN_2_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OMN_2_SIZE_OMN_2_SIZE_MASK, .index = STRELA_OMN_2_SIZE_OMN_2_SIZE_OFFSET })

// STRELA Output Memory Node 3 address register
#define STRELA_OMN_3_ADDR_REG_OFFSET 0x58

// STRELA Output Memory Node 3 size register
#define STRELA_OMN_3_SIZE_REG_OFFSET 0x5c
#define STRELA_OMN_3_SIZE_OMN_3_SIZE_MASK 0xffff
#define STRELA_OMN_3_SIZE_OMN_3_SIZE_OFFSET 0
#define STRELA_OMN_3_SIZE_OMN_3_SIZE_FIELD \
  ((bitfield_field32_t) { .mask = STRELA_OMN_3_SIZE_OMN_3_SIZE_MASK, .index = STRELA_OMN_3_SIZE_OMN_3_SIZE_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _STRELA_REG_DEFS_
// End generated register defines for strela