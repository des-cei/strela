// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module shifter #(
  parameter int DATA_WIDTH = 32
) (
  input logic [DATA_WIDTH-1:0] a_i,
  input logic [DATA_WIDTH-1:0] b_i,
  input logic sr_mode_i,
  output logic [DATA_WIDTH-1:0] res_o
);

  logic signed [$clog2(DATA_WIDTH):0] shift_amt;
  /* verilator lint_off WIDTHTRUNC */
  assign shift_amt = $signed(b_i);
  /* verilator lint_on WIDTHTRUNC */

`ifdef ASIC
  `define ASH_MOD DW01_ash
`else
  `define ASH_MOD ash
`endif

  `ASH_MOD #(
    .A_width (DATA_WIDTH),
    .SH_width($clog2(DATA_WIDTH) + 1)
  ) U1 (
    .A(a_i),
    .DATA_TC(sr_mode_i & a_i[DATA_WIDTH-1]),
    .SH(shift_amt),
    .SH_TC(shift_amt[$clog2(DATA_WIDTH)]),
    .B(res_o)
  );

endmodule
