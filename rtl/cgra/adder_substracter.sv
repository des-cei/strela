// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module adder_substracter #(
  parameter int DATA_WIDTH = 32
) (
  input logic [DATA_WIDTH-1:0] a_i,
  input logic [DATA_WIDTH-1:0] b_i,
  input logic addsub_mode_i,
  output logic [DATA_WIDTH-1:0] res_o
);

  logic carry_out;

`ifdef ASIC
  `define ADDSUB_MOD DW01_addsub
`else
  `define ADDSUB_MOD addsub
`endif

  `ADDSUB_MOD #(
    .width(DATA_WIDTH)
  ) U1 (
    .A(a_i),
    .B(b_i),
    .CI(1'b0),
    .ADD_SUB(addsub_mode_i),
    .SUM(res_o),
    .CO(carry_out)
  );

endmodule
