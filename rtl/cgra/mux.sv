// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module mux #(
    parameter int NUM_INPUTS = 2,
    parameter int DATA_WIDTH = 32
) (
    // Configuration
    input logic [$clog2(NUM_INPUTS)-1:0] sel_i,

    // Multiplexer signals
    input  logic [NUM_INPUTS*DATA_WIDTH-1:0] mux_i,
    output logic [           DATA_WIDTH-1:0] mux_o
);

  logic [DATA_WIDTH-1:0] inputs[NUM_INPUTS];

  for (genvar i = 0; i < NUM_INPUTS; i++) begin
    assign inputs[i] = mux_i[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
  end

  always_comb begin
    mux_o = '0;
    for (int unsigned i = 0; i < NUM_INPUTS; i++) begin
      if (sel_i == $bits(sel_i)'(i)) mux_o = inputs[i];
    end
  end

endmodule
