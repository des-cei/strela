// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module PC_superpolyvalent #(
    parameter int DATA_WIDTH = 32
) (
    // Clock and reset
    input logic clk_i,
    input logic rst_ni,
    input logic clr_i,

    // Input data
    input  logic [DATA_WIDTH-1:0] north_din_i,
    input  logic                  north_din_v_i,
    input  logic [DATA_WIDTH-1:0] east_din_i,
    input  logic                  east_din_v_i,
    input  logic [DATA_WIDTH-1:0] south_din_i,
    input  logic                  south_din_v_i,
    input  logic [DATA_WIDTH-1:0] west_din_i,
    input  logic                  west_din_v_i,
    output logic                  din_1_r_o,
    output logic                  din_2_r_o,
    output logic                  cin_r_o,

    // Output data
    output logic [DATA_WIDTH-1:0] dout_o,
    output logic                  dout_v_o,
    output logic                  dout_d_v_o,
    output logic                  dout_b1_v_o,
    output logic                  dout_b2_v_o,
    input  logic                  north_dout_r_i,
    input  logic                  east_dout_r_i,
    input  logic                  south_dout_r_i,
    input  logic                  west_dout_r_i,

    // Configuration
    input logic [107:0] conf_bits_i,
    input logic [  1:0] eb_en_i
);
  // synopsys sync_set_reset clr_i

  // Config signals
  logic [2:0] mux_sel_1, mux_sel_2;
  logic [           1:0] mux_sel_c;
  logic                  feedback;
  logic [           3:0] alu_sel;
  logic                  cmp_sel;
  logic [           1:0] out_sel;
  logic [           5:0] mask_fs;
  logic [           1:0] jm_mode;
  logic                  initial_valid;
  logic [DATA_WIDTH-1:0] I1_const;
  logic [DATA_WIDTH-1:0] initial_data;
  logic [          15:0] delay_value;

  // Interconnect signals
  logic [DATA_WIDTH-1:0] EB_din_1, EB_din_2, jm_din_1, jm_din_2, jm_dout_1, jm_dout_2;
  logic EB_din_1_v, EB_din_2_v;
  logic jm_din_1_v, jm_din_1_r, jm_din_2_v, jm_din_2_r, jm_dout_v;
  logic jm_cin, jm_cin_v, jm_cout;
  logic dout_r;

  // Configuration decoding
  assign mux_sel_1     = conf_bits_i[2:0];
  assign mux_sel_2     = conf_bits_i[5:3];
  assign mux_sel_c     = conf_bits_i[7:6];
  assign feedback      = conf_bits_i[8];
  assign alu_sel       = conf_bits_i[12:9];
  assign cmp_sel       = conf_bits_i[13];
  assign out_sel       = conf_bits_i[15:14];
  assign mask_fs       = conf_bits_i[21:16];
  assign jm_mode       = conf_bits_i[23:22];
  assign initial_valid = conf_bits_i[24];
  assign initial_data  = DATA_WIDTH'(signed'(conf_bits_i[59:28]));
  assign I1_const      = DATA_WIDTH'(signed'(conf_bits_i[91:60]));
  assign delay_value   = conf_bits_i[107:92];

  // Data path 1
  mux #(
      .NUM_INPUTS(6),
      .DATA_WIDTH(DATA_WIDTH)
  ) MUX_1 (
      .sel_i(mux_sel_1),
      .mux_i({dout_o, I1_const, west_din_i, south_din_i, east_din_i, north_din_i}),
      .mux_o(EB_din_1)
  );

  mux #(
      .NUM_INPUTS(6),
      .DATA_WIDTH(1)
  ) MUX_1_v (
      .sel_i(mux_sel_1),
      .mux_i({dout_v_o, 1'b1, west_din_v_i, south_din_v_i, east_din_v_i, north_din_v_i}),
      .mux_o(EB_din_1_v)
  );

  elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
  ) REG_1 (
      .clk_i,
      .rst_ni,
      .clr_i,
      .en_i    (eb_en_i[0]),
      .din_i   (EB_din_1),
      .din_v_i (EB_din_1_v),
      .din_r_o (din_1_r_o),
      .dout_o  (jm_din_1),
      .dout_v_o(jm_din_1_v),
      .dout_r_i(jm_din_1_r)
  );

  // Data path 2
  mux #(
      .NUM_INPUTS(6),
      .DATA_WIDTH(DATA_WIDTH)
  ) MUX_2 (
      .sel_i(mux_sel_2),
      .mux_i({dout_o, I1_const, west_din_i, south_din_i, east_din_i, north_din_i}),
      .mux_o(EB_din_2)
  );

  mux #(
      .NUM_INPUTS(6),
      .DATA_WIDTH(1)
  ) MUX_2_v (
      .sel_i(mux_sel_2),
      .mux_i({dout_v_o, 1'b1, west_din_v_i, south_din_v_i, east_din_v_i, north_din_v_i}),
      .mux_o(EB_din_2_v)
  );

  elastic_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
  ) REG_2 (
      .clk_i,
      .rst_ni,
      .clr_i,
      .en_i    (eb_en_i[1]),
      .din_i   (EB_din_2),
      .din_v_i (EB_din_2_v),
      .din_r_o (din_2_r_o),
      .dout_o  (jm_din_2),
      .dout_v_o(jm_din_2_v),
      .dout_r_i(jm_din_2_r)
  );

  // Control path
  mux #(
      .NUM_INPUTS(4),
      .DATA_WIDTH(1)
  ) MUX_C (
      .sel_i(mux_sel_c),
      .mux_i({west_din_i[0], south_din_i[0], east_din_i[0], north_din_i[0]}),
      .mux_o(jm_cin)
  );

  mux #(
      .NUM_INPUTS(4),
      .DATA_WIDTH(1)
  ) MUX_C_v (
      .sel_i(mux_sel_c),
      .mux_i({west_din_v_i, south_din_v_i, east_din_v_i, north_din_v_i}),
      .mux_o(jm_cin_v)
  );

  // Data path out    
  join_merge #(
      .DATA_WIDTH(DATA_WIDTH)
  ) join_merge_inst (
      .mode_i   (jm_mode),
      .din_1_i  (jm_din_1),
      .din_1_v_i(jm_din_1_v),
      .din_1_r_o(jm_din_1_r),
      .din_2_i  (jm_din_2),
      .din_2_v_i(jm_din_2_v),
      .din_2_r_o(jm_din_2_r),
      .cin_i    (jm_cin),
      .cin_v_i  (jm_cin_v),
      .cin_r_o  (cin_r_o),
      .dout_1_o (jm_dout_1),
      .dout_2_o (jm_dout_2),
      .cout_o   (jm_cout),
      .out_v_o  (jm_dout_v),
      .out_r_i  (dout_r)
  );

  // Data path
  FU_data_superpolyvalent #(
      .DATA_WIDTH(DATA_WIDTH)
  ) FU_data (
      .clk_i,
      .rst_ni,
      .clr_i,
      .en_i          (jm_dout_v && dout_r),
      .initial_data_i(initial_data),
      .feedback_i    (feedback),
      .alu_sel_i     (alu_sel),
      .cmp_sel_i     (cmp_sel),
      .out_sel_i     (out_sel),
      .din_1_i       (jm_dout_1),
      .din_2_i       (jm_dout_2),
      .cin_i         (jm_cout),
      .dout_o        (dout_o)
  );

  // Control path
  FU_control_superpolyvalent FU_control (
      .clk_i,
      .rst_ni,
      .clr_i,
      .initial_valid_i(initial_valid),
      .delay_value_i  (delay_value),
      .fork_mask_i    (mask_fs),
      .cin_i          (jm_cout),
      .in_v_i         (jm_dout_v),
      .in_r_o         (dout_r),
      .out_v_o        (dout_v_o),
      .out_d_v_o      (dout_d_v_o),
      .out_b1_v_o     (dout_b1_v_o),
      .out_b2_v_o     (dout_b2_v_o),
      .din_1_r_i      (din_1_r_o),
      .din_2_r_i      (din_2_r_o),
      .east_dout_r_i  (east_dout_r_i),
      .west_dout_r_i  (west_dout_r_i),
      .north_dout_r_i (north_dout_r_i),
      .south_dout_r_i (south_dout_r_i)
  );

endmodule
