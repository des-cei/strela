// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module mult #(
  parameter int A_width = 16,
  parameter int B_width = 16
) (
  input  logic [        A_width-1:0] A,
  input  logic [        B_width-1:0] B,
  input  logic                       TC,
  output logic [A_width+B_width-1:0] PRODUCT
);
  wire signed [A_width-1:0] A_signed = A;
  wire signed [B_width-1:0] B_signed = B;

  wire [A_width-1:0] A_unsigned = A;
  wire [B_width-1:0] B_unsigned = B;

  always_comb begin
    if (TC) PRODUCT = $signed(A_signed) * $signed(B_signed);
    else PRODUCT = A_unsigned * B_unsigned;
  end

endmodule
