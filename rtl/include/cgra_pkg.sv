// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

package cgra_pkg;

  // General configuration
  localparam INPUT_NODES  = 4;
  localparam OUTPUT_NODES = 4;
  localparam NODES        = INPUT_NODES + OUTPUT_NODES + 1;

  // MMIO registers
  localparam CONFIG_REG_N           = 4 + INPUT_NODES*2 + OUTPUT_NODES*2;
  localparam CONTROL_REG_ADDR       = 8'h0;
  localparam CONFIG_ADDR_ADDR       = 8'h4;
  localparam CONFIG_SIZE_ADDR       = 8'h8;
  localparam SEW_ADDR               = 8'hC;
  localparam INPUT_REGS_BASE_ADDR   = 8'h10;
  localparam OUTPUT_REGS_BASE_ADDR  = 8'h50;
  localparam CTR_BS_REG_ADDR        = 8'h90;
  localparam CTR_EXEC_REG_ADDR      = 8'h94;
  localparam CTR_STALL_REG_ADDR     = 8'h98;

  // Memory parameters
  localparam WORST_MEM_LATENCY = 4;
  localparam FIFO_DEPTH = 8;
  localparam FIFO_PTR_WIDTH = $clog2(FIFO_DEPTH);

  // Main FSM type
  typedef enum logic [1:0] {
    S_MAIN_IDLE = 2'b00,
    S_MAIN_WAIT = 2'b01,
    S_MAIN_EXEC = 2'b10,
    S_MAIN_DONE = 2'b11
  } main_fsm_t;

endpackage
