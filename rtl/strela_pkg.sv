// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

package strela_pkg;

  // General configuration
  localparam int unsigned NUM_ISE = 4;
  localparam int unsigned NUM_OSE = 4;
  localparam int unsigned NUM_SE = NUM_ISE + NUM_OSE;

  // Configuration parameters
  localparam logic [15:0] CONF_STRIDE = 16'd4;
  localparam logic [15:0] CONF_SIZE = 16'd80;
  localparam logic [3:0][31:0] CONF_OFFSET = {32'd240, 32'd160, 32'd80, 32'd0};

  // Stream engine parameters
  localparam int unsigned SE_FIFO_DEPTH = 8;

  // Selected element width, obione's sew_i encoding
  localparam logic [2:0] SEW_8 = 3'd3;
  localparam logic [2:0] SEW_16 = 3'd4;
  localparam logic [2:0] SEW_32 = 3'd5;

  // Main FSM type
  typedef enum logic [1:0] {
    S_MAIN_IDLE = 2'b00,
    S_MAIN_WAIT = 2'b01,
    S_MAIN_EXEC = 2'b10,
    S_MAIN_DONE = 2'b11
  } main_fsm_t;

endpackage
