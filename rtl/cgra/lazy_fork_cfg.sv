// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// -----------------------------------------------------------------------------
// Configurable lazy (strict) fork for elastic channels, valid/ready protocol.
//
// The transfer is atomic: valid is asserted towards each enabled branch only
// when every other enabled branch is ready, so all enabled branches consume
// the token in the same cycle. No state is required.
//
// Note that valid_o[i] does not depend on ready_i[i] itself. This avoids a
// combinational loop when a consumer generates its ready as a function of
// the incoming valid. The handshake on branch i still requires ready_i[i],
// enforced through ready_o.
//
// fork_mask_i enables each output branch. Disabled branches never assert
// valid and are excluded from the readiness conjunction. With
// fork_mask_i == '0 the fork behaves as a sink (ready_o = 1, token dropped).
//
// Unlike the eager fork, fork_mask_i may change at any idle cycle without
// risk of token duplication, since there is no internal state. It must still
// remain stable within a cycle relative to clk_i domain logic.
// -----------------------------------------------------------------------------

module lazy_fork_cfg #(
  parameter int unsigned NUM_BRANCHES = 4,
  parameter int unsigned DATA_WIDTH   = 32
) (
  // Configuration: 1 enables the branch, 0 disables it
  input logic [NUM_BRANCHES-1:0] fork_mask_i,

  // Input elastic channel
  input  logic                  valid_i,
  output logic                  ready_o,
  input  logic [DATA_WIDTH-1:0] data_i,

  // Output elastic channels
  output logic [NUM_BRANCHES-1:0]                 valid_o,
  input  logic [NUM_BRANCHES-1:0]                 ready_i,
  output logic [NUM_BRANCHES-1:0][DATA_WIDTH-1:0] data_o
);

  // A branch blocks the transfer if enabled and not ready
  logic [NUM_BRANCHES-1:0] blocking;

  assign blocking = fork_mask_i & ~ready_i;

  // Ready towards the sender: every enabled branch is ready
  assign ready_o  = ~(|blocking);

  // Valid towards branch i: token offered, branch enabled, and every OTHER
  // enabled branch ready. Excluding the branch's own ready breaks potential
  // combinational loops through the consumer.
  for (genvar g = 0; g < NUM_BRANCHES; g++) begin : gen_valid
    logic others_ready;
    assign others_ready = ~(|(blocking & ~(NUM_BRANCHES'(1) << g)));
    assign valid_o[g]   = valid_i & fork_mask_i[g] & others_ready;
  end

  // Data broadcast
  for (genvar g = 0; g < NUM_BRANCHES; g++) begin : gen_data
    assign data_o[g] = data_i;
  end

endmodule
