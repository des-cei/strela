// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

package strela_pkg;

  // General configuration
  localparam INPUT_NODES  = 4;
  localparam OUTPUT_NODES = 4;
  localparam NODES        = INPUT_NODES + OUTPUT_NODES;

  // Configuration parameters
  localparam logic [15:0] CONF_STRIDE = 16'd4;
  localparam logic [15:0] CONF_SIZE = 16'd80;
  localparam logic [3:0][31:0] CONF_OFFSET = {32'd240, 32'd160, 32'd80, 32'd0};

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
