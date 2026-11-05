// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module multiplier #(
  parameter int DATA_WIDTH = 32
) (
  input  logic signed [DATA_WIDTH-1:0] a_i,
  input  logic signed [DATA_WIDTH-1:0] b_i,
  output logic signed [DATA_WIDTH-1:0] res_o
);

  logic signed [2*DATA_WIDTH-1:0] res;
  assign res_o = res[DATA_WIDTH-1:0];

`ifdef ASIC
  `define MULT_MOD DW02_mult
`else
  `define MULT_MOD mult
`endif

  `MULT_MOD #(
    .A_width(DATA_WIDTH),
    .B_width(DATA_WIDTH)
  ) U1 (
    .A(a_i),
    .B(b_i),
    .TC(1'b1),
    .PRODUCT(res)
  );

endmodule
