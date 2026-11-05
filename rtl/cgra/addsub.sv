// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module addsub #(
  parameter int width = 32
) (
  input  logic [width-1:0] A,
  input  logic [width-1:0] B,
  input  logic             CI,
  input  logic             ADD_SUB,
  output logic [width-1:0] SUM,
  output logic             CO
);

  wire  [width-1:0] B_x = B ^ {width{ADD_SUB}};
  wire              cin = CI ^ ADD_SUB;

  logic [  width:0] acc;
  /* verilator lint_off WIDTHEXPAND */
  assign acc = {1'b0, A} + {1'b0, B_x} + cin;
  /* verilator lint_on WIDTHEXPAND */

  assign SUM = acc[width-1:0];
  assign CO  = acc[width];

endmodule
