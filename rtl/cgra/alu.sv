// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module alu #(
  parameter int DATA_WIDTH = 32
) (
  input logic [DATA_WIDTH-1:0] din_1_i,
  input logic [DATA_WIDTH-1:0] din_2_i,
  input logic [           2:0] alu_sel_i,

  output logic [DATA_WIDTH-1:0] dout_o
);
  logic [DATA_WIDTH-1:0] add_sub_dout, mult_dout, shifter_dout;
  logic addsub_mode, sr_mode;

  always_comb begin
    sr_mode = 1'b0;
    addsub_mode = 1'b0;

    case (alu_sel_i)
      0: begin
        dout_o = add_sub_dout;
      end

      1: begin
        dout_o = mult_dout;
      end

      2: begin
        dout_o = add_sub_dout;
        addsub_mode = 1'b1;
      end

      3: begin
        dout_o = shifter_dout;
      end

      4: begin
        dout_o  = shifter_dout;
        sr_mode = 1'b1;
      end

      5: begin
        dout_o = din_1_i & din_2_i;
      end

      6: begin
        dout_o = din_1_i | din_2_i;
      end

      7: begin
        dout_o = din_1_i ^ din_2_i;
      end
      default: ;
    endcase
  end

  // Add/sub
  adder_substracter #(
    .DATA_WIDTH(DATA_WIDTH)
  ) add_sub_i (
    .a_i(din_1_i),
    .b_i(din_2_i),
    .addsub_mode_i(addsub_mode),
    .res_o(add_sub_dout)
  );

  // Multiplier
  multiplier #(
    .DATA_WIDTH(DATA_WIDTH)
  ) mult_i (
    .a_i  (din_1_i),
    .b_i  (din_2_i),
    .res_o(mult_dout)
  );

  // Shifter
  shifter #(
    .DATA_WIDTH(DATA_WIDTH)
  ) shifter_i (
    .a_i(din_1_i),
    .b_i(din_2_i),
    .sr_mode_i(sr_mode),
    .res_o(shifter_dout)
  );

endmodule
