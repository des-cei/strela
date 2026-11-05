// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// -----------------------------------------------------------------------------
// Configurable eager fork for elastic channels, valid/ready protocol.
// Asynchronous active-low reset plus synchronous active-high clear.
//
// rst_ni : global asynchronous reset (power-on, SoC hard reset)
// clr_i  : synchronous clear, re-arms all flags. Intended to flush the fork
//          state between kernel executions without exercising the reset tree.
//
// fork_mask_i enables each output branch. A disabled branch never asserts
// valid and never stalls the sender. fork_mask_i is assumed quasi-static.
// -----------------------------------------------------------------------------

module eager_fork_cfg #(
  parameter int unsigned NUM_BRANCHES = 4,
  parameter int unsigned DATA_WIDTH   = 32
) (
  input logic clk_i,
  input logic rst_ni,  // asynchronous, active low
  input logic clr_i,   // synchronous, active high

  // Configuration: 1 enables the branch, 0 disables it
  input logic [NUM_BRANCHES-1:0] fork_mask_i,

  // Input elastic channel
  input  logic [DATA_WIDTH-1:0] data_i,
  input  logic                  valid_i,
  output logic                  ready_o,

  // Output elastic channels
  output logic [NUM_BRANCHES-1:0][DATA_WIDTH-1:0] data_o,
  output logic [NUM_BRANCHES-1:0]                 valid_o,
  input  logic [NUM_BRANCHES-1:0]                 ready_i
);

  logic [NUM_BRANCHES-1:0] flag_q, flag_d;
  logic [NUM_BRANCHES-1:0] active;
  logic [NUM_BRANCHES-1:0] pending;

  assign active  = flag_q & fork_mask_i;
  assign pending = active & ~ready_i;
  assign ready_o = ~(|pending);
  assign valid_o = {NUM_BRANCHES{valid_i}} & active;

  always_comb begin
    flag_d = flag_q;
    if (valid_i) begin
      flag_d = {NUM_BRANCHES{ready_o}} | pending;
    end
  end

  // Asynchronous reset, synchronous clear. The clear has priority over
  // the datapath update and re-arms all flags.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      flag_q <= '1;
    end else if (clr_i) begin
      flag_q <= '1;
    end else begin
      flag_q <= flag_d;
    end
  end

  for (genvar g = 0; g < NUM_BRANCHES; g++) begin : gen_data
    assign data_o[g] = data_i;
  end

endmodule
