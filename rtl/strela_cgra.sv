// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela_cgra
  import cgra_pkg::*;
#(
  parameter int DATA_WIDTH = 32,
  parameter config_border_t CONFIG_BORDER = NORTH
) (
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Input data
  input logic [4*DATA_WIDTH-1:0] din_i,
  input logic [3:0] din_v_i,
  output logic [3:0] din_r_o,

  // Output data
  output logic [4*DATA_WIDTH-1:0] dout_o,
  output logic [3:0] dout_v_o,
  input logic [3:0] dout_r_i,

  // Configuration
  input logic [3:0] conf_en_i
);

  // Internal data signals
  logic [3:0][2:0][DATA_WIDTH-1:0] hor_we;
  logic [3:0][2:0][DATA_WIDTH-1:0] hor_ew;
  logic [3:0][2:0] hor_we_v;
  logic [3:0][2:0] hor_we_r;
  logic [3:0][2:0] hor_ew_v;
  logic [3:0][2:0] hor_ew_r;
  logic [2:0][3:0][DATA_WIDTH-1:0] ver_ns;
  logic [2:0][3:0][DATA_WIDTH-1:0] ver_sn;
  logic [2:0][3:0] ver_ns_v;
  logic [2:0][3:0] ver_ns_r;
  logic [2:0][3:0] ver_sn_v;
  logic [2:0][3:0] ver_sn_r;
  logic [2:0][DATA_WIDTH-1:0] lat_west;
  logic [2:0][DATA_WIDTH-1:0] lat_east;
  logic [2:0] lat_west_v;
  logic [2:0] lat_west_r;
  logic [2:0] lat_east_v;
  logic [2:0] lat_east_r;


  // Internal config signals
  logic [2:0][3:0] conf_en;

  // External data signals
  logic [3:0][DATA_WIDTH-1:0] wire_din;
  logic [3:0] wire_din_v;
  logic [3:0] wire_din_r;
  logic [3:0][DATA_WIDTH-1:0] wire_dout;
  logic [3:0] wire_dout_v;
  logic [3:0] wire_dout_r;

  // Split inputs
  for (genvar i = 0; i < 4; i++) begin : gen_split_inputs
    assign wire_din[i] = din_i[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
    assign wire_din_v[i] = din_v_i[i];
    assign din_r_o[i] = wire_din_r[i];
  end : gen_split_inputs

  // Split outputs
  for (genvar i = 0; i < 4; i++) begin : gen_join_outputs
    assign dout_o[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = wire_dout[i];
    assign dout_v_o[i] = wire_dout_v[i];
    assign wire_dout_r[i] = dout_r_i[i];
  end : gen_join_outputs

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_0 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (wire_din[0]),
    .north_din_v_i (wire_din_v[0]),
    .north_din_r_o (wire_din_r[0]),
    .east_din_i    (hor_we[0][0]),
    .east_din_v_i  (hor_we_v[0][0]),
    .east_din_r_o  (hor_we_r[0][0]),
    .south_din_i   (ver_ns[0][0]),
    .south_din_v_i (ver_ns_v[0][0]),
    .south_din_r_o (ver_ns_r[0][0]),
    .west_din_i    ('0),
    .west_din_v_i  (1'b0),
    .west_din_r_o  (),
    .north_dout_o  (),
    .north_dout_v_o(),
    .north_dout_r_i(1'b0),
    .east_dout_o   (hor_ew[0][0]),
    .east_dout_v_o (hor_ew_v[0][0]),
    .east_dout_r_i (hor_ew_r[0][0]),
    .south_dout_o  (ver_sn[0][0]),
    .south_dout_v_o(ver_sn_v[0][0]),
    .south_dout_r_i(ver_sn_r[0][0]),
    .west_dout_o   (lat_west[0]),
    .west_dout_v_o (lat_west_v[0]),
    .west_dout_r_i (lat_west_r[0]),
    .conf_en_i     (conf_en_i[0]),
    .conf_en_o     (conf_en[0][0])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_1 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (wire_din[1]),
    .north_din_v_i (wire_din_v[1]),
    .north_din_r_o (wire_din_r[1]),
    .east_din_i    (hor_we[0][1]),
    .east_din_v_i  (hor_we_v[0][1]),
    .east_din_r_o  (hor_we_r[0][1]),
    .south_din_i   (ver_ns[0][1]),
    .south_din_v_i (ver_ns_v[0][1]),
    .south_din_r_o (ver_ns_r[0][1]),
    .west_din_i    (hor_ew[0][0]),
    .west_din_v_i  (hor_ew_v[0][0]),
    .west_din_r_o  (hor_ew_r[0][0]),
    .north_dout_o  (),
    .north_dout_v_o(),
    .north_dout_r_i(1'b0),
    .east_dout_o   (hor_ew[0][1]),
    .east_dout_v_o (hor_ew_v[0][1]),
    .east_dout_r_i (hor_ew_r[0][1]),
    .south_dout_o  (ver_sn[0][1]),
    .south_dout_v_o(ver_sn_v[0][1]),
    .south_dout_r_i(ver_sn_r[0][1]),
    .west_dout_o   (hor_we[0][0]),
    .west_dout_v_o (hor_we_v[0][0]),
    .west_dout_r_i (hor_we_r[0][0]),
    .conf_en_i     (conf_en_i[1]),
    .conf_en_o     (conf_en[0][1])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_2 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (wire_din[2]),
    .north_din_v_i (wire_din_v[2]),
    .north_din_r_o (wire_din_r[2]),
    .east_din_i    (hor_we[0][2]),
    .east_din_v_i  (hor_we_v[0][2]),
    .east_din_r_o  (hor_we_r[0][2]),
    .south_din_i   (ver_ns[0][2]),
    .south_din_v_i (ver_ns_v[0][2]),
    .south_din_r_o (ver_ns_r[0][2]),
    .west_din_i    (hor_ew[0][1]),
    .west_din_v_i  (hor_ew_v[0][1]),
    .west_din_r_o  (hor_ew_r[0][1]),
    .north_dout_o  (),
    .north_dout_v_o(),
    .north_dout_r_i(1'b0),
    .east_dout_o   (hor_ew[0][2]),
    .east_dout_v_o (hor_ew_v[0][2]),
    .east_dout_r_i (hor_ew_r[0][2]),
    .south_dout_o  (ver_sn[0][2]),
    .south_dout_v_o(ver_sn_v[0][2]),
    .south_dout_r_i(ver_sn_r[0][2]),
    .west_dout_o   (hor_we[0][1]),
    .west_dout_v_o (hor_we_v[0][1]),
    .west_dout_r_i (hor_we_r[0][1]),
    .conf_en_i     (conf_en_i[2]),
    .conf_en_o     (conf_en[0][2])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_3 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (wire_din[3]),
    .north_din_v_i (wire_din_v[3]),
    .north_din_r_o (wire_din_r[3]),
    .east_din_i    ('0),
    .east_din_v_i  (1'b0),
    .east_din_r_o  (),
    .south_din_i   (ver_ns[0][3]),
    .south_din_v_i (ver_ns_v[0][3]),
    .south_din_r_o (ver_ns_r[0][3]),
    .west_din_i    (hor_ew[0][2]),
    .west_din_v_i  (hor_ew_v[0][2]),
    .west_din_r_o  (hor_ew_r[0][2]),
    .north_dout_o  (),
    .north_dout_v_o(),
    .north_dout_r_i(1'b0),
    .east_dout_o   (lat_east[0]),
    .east_dout_v_o (lat_east_v[0]),
    .east_dout_r_i (lat_east_r[0]),
    .south_dout_o  (ver_sn[0][3]),
    .south_dout_v_o(ver_sn_v[0][3]),
    .south_dout_r_i(ver_sn_r[0][3]),
    .west_dout_o   (hor_we[0][2]),
    .west_dout_v_o (hor_we_v[0][2]),
    .west_dout_r_i (hor_we_r[0][2]),
    .conf_en_i     (conf_en_i[3]),
    .conf_en_o     (conf_en[0][3])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_4 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[0][0]),
    .north_din_v_i (ver_sn_v[0][0]),
    .north_din_r_o (ver_sn_r[0][0]),
    .east_din_i    (hor_we[1][0]),
    .east_din_v_i  (hor_we_v[1][0]),
    .east_din_r_o  (hor_we_r[1][0]),
    .south_din_i   (ver_ns[1][0]),
    .south_din_v_i (ver_ns_v[1][0]),
    .south_din_r_o (ver_ns_r[1][0]),
    .west_din_i    (lat_west[0]),
    .west_din_v_i  (lat_west_v[0]),
    .west_din_r_o  (lat_west_r[0]),
    .north_dout_o  (ver_ns[0][0]),
    .north_dout_v_o(ver_ns_v[0][0]),
    .north_dout_r_i(ver_ns_r[0][0]),
    .east_dout_o   (hor_ew[1][0]),
    .east_dout_v_o (hor_ew_v[1][0]),
    .east_dout_r_i (hor_ew_r[1][0]),
    .south_dout_o  (ver_sn[1][0]),
    .south_dout_v_o(ver_sn_v[1][0]),
    .south_dout_r_i(ver_sn_r[1][0]),
    .west_dout_o   (lat_west[1]),
    .west_dout_v_o (lat_west_v[1]),
    .west_dout_r_i (lat_west_r[1]),
    .conf_en_i     (conf_en[0][0]),
    .conf_en_o     (conf_en[1][0])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_5 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[0][1]),
    .north_din_v_i (ver_sn_v[0][1]),
    .north_din_r_o (ver_sn_r[0][1]),
    .east_din_i    (hor_we[1][1]),
    .east_din_v_i  (hor_we_v[1][1]),
    .east_din_r_o  (hor_we_r[1][1]),
    .south_din_i   (ver_ns[1][1]),
    .south_din_v_i (ver_ns_v[1][1]),
    .south_din_r_o (ver_ns_r[1][1]),
    .west_din_i    (hor_ew[1][0]),
    .west_din_v_i  (hor_ew_v[1][0]),
    .west_din_r_o  (hor_ew_r[1][0]),
    .north_dout_o  (ver_ns[0][1]),
    .north_dout_v_o(ver_ns_v[0][1]),
    .north_dout_r_i(ver_ns_r[0][1]),
    .east_dout_o   (hor_ew[1][1]),
    .east_dout_v_o (hor_ew_v[1][1]),
    .east_dout_r_i (hor_ew_r[1][1]),
    .south_dout_o  (ver_sn[1][1]),
    .south_dout_v_o(ver_sn_v[1][1]),
    .south_dout_r_i(ver_sn_r[1][1]),
    .west_dout_o   (hor_we[1][0]),
    .west_dout_v_o (hor_we_v[1][0]),
    .west_dout_r_i (hor_we_r[1][0]),
    .conf_en_i     (conf_en[0][1]),
    .conf_en_o     (conf_en[1][1])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_6 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[0][2]),
    .north_din_v_i (ver_sn_v[0][2]),
    .north_din_r_o (ver_sn_r[0][2]),
    .east_din_i    (hor_we[1][2]),
    .east_din_v_i  (hor_we_v[1][2]),
    .east_din_r_o  (hor_we_r[1][2]),
    .south_din_i   (ver_ns[1][2]),
    .south_din_v_i (ver_ns_v[1][2]),
    .south_din_r_o (ver_ns_r[1][2]),
    .west_din_i    (hor_ew[1][1]),
    .west_din_v_i  (hor_ew_v[1][1]),
    .west_din_r_o  (hor_ew_r[1][1]),
    .north_dout_o  (ver_ns[0][2]),
    .north_dout_v_o(ver_ns_v[0][2]),
    .north_dout_r_i(ver_ns_r[0][2]),
    .east_dout_o   (hor_ew[1][2]),
    .east_dout_v_o (hor_ew_v[1][2]),
    .east_dout_r_i (hor_ew_r[1][2]),
    .south_dout_o  (ver_sn[1][2]),
    .south_dout_v_o(ver_sn_v[1][2]),
    .south_dout_r_i(ver_sn_r[1][2]),
    .west_dout_o   (hor_we[1][1]),
    .west_dout_v_o (hor_we_v[1][1]),
    .west_dout_r_i (hor_we_r[1][1]),
    .conf_en_i     (conf_en[0][2]),
    .conf_en_o     (conf_en[1][2])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_7 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[0][3]),
    .north_din_v_i (ver_sn_v[0][3]),
    .north_din_r_o (ver_sn_r[0][3]),
    .east_din_i    (lat_east[0]),
    .east_din_v_i  (lat_east_v[0]),
    .east_din_r_o  (lat_east_r[0]),
    .south_din_i   (ver_ns[1][3]),
    .south_din_v_i (ver_ns_v[1][3]),
    .south_din_r_o (ver_ns_r[1][3]),
    .west_din_i    (hor_ew[1][2]),
    .west_din_v_i  (hor_ew_v[1][2]),
    .west_din_r_o  (hor_ew_r[1][2]),
    .north_dout_o  (ver_ns[0][3]),
    .north_dout_v_o(ver_ns_v[0][3]),
    .north_dout_r_i(ver_ns_r[0][3]),
    .east_dout_o   (lat_east[1]),
    .east_dout_v_o (lat_east_v[1]),
    .east_dout_r_i (lat_east_r[1]),
    .south_dout_o  (ver_sn[1][3]),
    .south_dout_v_o(ver_sn_v[1][3]),
    .south_dout_r_i(ver_sn_r[1][3]),
    .west_dout_o   (hor_we[1][2]),
    .west_dout_v_o (hor_we_v[1][2]),
    .west_dout_r_i (hor_we_r[1][2]),
    .conf_en_i     (conf_en[0][3]),
    .conf_en_o     (conf_en[1][3])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_8 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[1][0]),
    .north_din_v_i (ver_sn_v[1][0]),
    .north_din_r_o (ver_sn_r[1][0]),
    .east_din_i    (hor_we[2][0]),
    .east_din_v_i  (hor_we_v[2][0]),
    .east_din_r_o  (hor_we_r[2][0]),
    .south_din_i   (ver_ns[2][0]),
    .south_din_v_i (ver_ns_v[2][0]),
    .south_din_r_o (ver_ns_r[2][0]),
    .west_din_i    (lat_west[1]),
    .west_din_v_i  (lat_west_v[1]),
    .west_din_r_o  (lat_west_r[1]),
    .north_dout_o  (ver_ns[1][0]),
    .north_dout_v_o(ver_ns_v[1][0]),
    .north_dout_r_i(ver_ns_r[1][0]),
    .east_dout_o   (hor_ew[2][0]),
    .east_dout_v_o (hor_ew_v[2][0]),
    .east_dout_r_i (hor_ew_r[2][0]),
    .south_dout_o  (ver_sn[2][0]),
    .south_dout_v_o(ver_sn_v[2][0]),
    .south_dout_r_i(ver_sn_r[2][0]),
    .west_dout_o   (lat_west[2]),
    .west_dout_v_o (lat_west_v[2]),
    .west_dout_r_i (lat_west_r[2]),
    .conf_en_i     (conf_en[1][0]),
    .conf_en_o     (conf_en[2][0])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_9 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[1][1]),
    .north_din_v_i (ver_sn_v[1][1]),
    .north_din_r_o (ver_sn_r[1][1]),
    .east_din_i    (hor_we[2][1]),
    .east_din_v_i  (hor_we_v[2][1]),
    .east_din_r_o  (hor_we_r[2][1]),
    .south_din_i   (ver_ns[2][1]),
    .south_din_v_i (ver_ns_v[2][1]),
    .south_din_r_o (ver_ns_r[2][1]),
    .west_din_i    (hor_ew[2][0]),
    .west_din_v_i  (hor_ew_v[2][0]),
    .west_din_r_o  (hor_ew_r[2][0]),
    .north_dout_o  (ver_ns[1][1]),
    .north_dout_v_o(ver_ns_v[1][1]),
    .north_dout_r_i(ver_ns_r[1][1]),
    .east_dout_o   (hor_ew[2][1]),
    .east_dout_v_o (hor_ew_v[2][1]),
    .east_dout_r_i (hor_ew_r[2][1]),
    .south_dout_o  (ver_sn[2][1]),
    .south_dout_v_o(ver_sn_v[2][1]),
    .south_dout_r_i(ver_sn_r[2][1]),
    .west_dout_o   (hor_we[2][0]),
    .west_dout_v_o (hor_we_v[2][0]),
    .west_dout_r_i (hor_we_r[2][0]),
    .conf_en_i     (conf_en[1][1]),
    .conf_en_o     (conf_en[2][1])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_10 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[1][2]),
    .north_din_v_i (ver_sn_v[1][2]),
    .north_din_r_o (ver_sn_r[1][2]),
    .east_din_i    (hor_we[2][2]),
    .east_din_v_i  (hor_we_v[2][2]),
    .east_din_r_o  (hor_we_r[2][2]),
    .south_din_i   (ver_ns[2][2]),
    .south_din_v_i (ver_ns_v[2][2]),
    .south_din_r_o (ver_ns_r[2][2]),
    .west_din_i    (hor_ew[2][1]),
    .west_din_v_i  (hor_ew_v[2][1]),
    .west_din_r_o  (hor_ew_r[2][1]),
    .north_dout_o  (ver_ns[1][2]),
    .north_dout_v_o(ver_ns_v[1][2]),
    .north_dout_r_i(ver_ns_r[1][2]),
    .east_dout_o   (hor_ew[2][2]),
    .east_dout_v_o (hor_ew_v[2][2]),
    .east_dout_r_i (hor_ew_r[2][2]),
    .south_dout_o  (ver_sn[2][2]),
    .south_dout_v_o(ver_sn_v[2][2]),
    .south_dout_r_i(ver_sn_r[2][2]),
    .west_dout_o   (hor_we[2][1]),
    .west_dout_v_o (hor_we_v[2][1]),
    .west_dout_r_i (hor_we_r[2][1]),
    .conf_en_i     (conf_en[1][2]),
    .conf_en_o     (conf_en[2][2])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_11 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[1][3]),
    .north_din_v_i (ver_sn_v[1][3]),
    .north_din_r_o (ver_sn_r[1][3]),
    .east_din_i    (lat_east[1]),
    .east_din_v_i  (lat_east_v[1]),
    .east_din_r_o  (lat_east_r[1]),
    .south_din_i   (ver_ns[2][3]),
    .south_din_v_i (ver_ns_v[2][3]),
    .south_din_r_o (ver_ns_r[2][3]),
    .west_din_i    (hor_ew[2][2]),
    .west_din_v_i  (hor_ew_v[2][2]),
    .west_din_r_o  (hor_ew_r[2][2]),
    .north_dout_o  (ver_ns[1][3]),
    .north_dout_v_o(ver_ns_v[1][3]),
    .north_dout_r_i(ver_ns_r[1][3]),
    .east_dout_o   (lat_east[2]),
    .east_dout_v_o (lat_east_v[2]),
    .east_dout_r_i (lat_east_r[2]),
    .south_dout_o  (ver_sn[2][3]),
    .south_dout_v_o(ver_sn_v[2][3]),
    .south_dout_r_i(ver_sn_r[2][3]),
    .west_dout_o   (hor_we[2][2]),
    .west_dout_v_o (hor_we_v[2][2]),
    .west_dout_r_i (hor_we_r[2][2]),
    .conf_en_i     (conf_en[1][3]),
    .conf_en_o     (conf_en[2][3])
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_12 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[2][0]),
    .north_din_v_i (ver_sn_v[2][0]),
    .north_din_r_o (ver_sn_r[2][0]),
    .east_din_i    (hor_we[3][0]),
    .east_din_v_i  (hor_we_v[3][0]),
    .east_din_r_o  (hor_we_r[3][0]),
    .south_din_i   ('0),
    .south_din_v_i (1'b0),
    .south_din_r_o (),
    .west_din_i    (lat_west[2]),
    .west_din_v_i  (lat_west_v[2]),
    .west_din_r_o  (lat_west_r[2]),
    .north_dout_o  (ver_ns[2][0]),
    .north_dout_v_o(ver_ns_v[2][0]),
    .north_dout_r_i(ver_ns_r[2][0]),
    .east_dout_o   (hor_ew[3][0]),
    .east_dout_v_o (hor_ew_v[3][0]),
    .east_dout_r_i (hor_ew_r[3][0]),
    .south_dout_o  (wire_dout[0]),
    .south_dout_v_o(wire_dout_v[0]),
    .south_dout_r_i(wire_dout_r[0]),
    .west_dout_o   (),
    .west_dout_v_o (),
    .west_dout_r_i (1'b0),
    .conf_en_i     (conf_en[2][0]),
    .conf_en_o     ()
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_13 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[2][1]),
    .north_din_v_i (ver_sn_v[2][1]),
    .north_din_r_o (ver_sn_r[2][1]),
    .east_din_i    (hor_we[3][1]),
    .east_din_v_i  (hor_we_v[3][1]),
    .east_din_r_o  (hor_we_r[3][1]),
    .south_din_i   ('0),
    .south_din_v_i (1'b0),
    .south_din_r_o (),
    .west_din_i    (hor_ew[3][0]),
    .west_din_v_i  (hor_ew_v[3][0]),
    .west_din_r_o  (hor_ew_r[3][0]),
    .north_dout_o  (ver_ns[2][1]),
    .north_dout_v_o(ver_ns_v[2][1]),
    .north_dout_r_i(ver_ns_r[2][1]),
    .east_dout_o   (hor_ew[3][1]),
    .east_dout_v_o (hor_ew_v[3][1]),
    .east_dout_r_i (hor_ew_r[3][1]),
    .south_dout_o  (wire_dout[1]),
    .south_dout_v_o(wire_dout_v[1]),
    .south_dout_r_i(wire_dout_r[1]),
    .west_dout_o   (hor_we[3][0]),
    .west_dout_v_o (hor_we_v[3][0]),
    .west_dout_r_i (hor_we_r[3][0]),
    .conf_en_i     (conf_en[2][1]),
    .conf_en_o     ()
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_14 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[2][2]),
    .north_din_v_i (ver_sn_v[2][2]),
    .north_din_r_o (ver_sn_r[2][2]),
    .east_din_i    (hor_we[3][2]),
    .east_din_v_i  (hor_we_v[3][2]),
    .east_din_r_o  (hor_we_r[3][2]),
    .south_din_i   ('0),
    .south_din_v_i (1'b0),
    .south_din_r_o (),
    .west_din_i    (hor_ew[3][1]),
    .west_din_v_i  (hor_ew_v[3][1]),
    .west_din_r_o  (hor_ew_r[3][1]),
    .north_dout_o  (ver_ns[2][2]),
    .north_dout_v_o(ver_ns_v[2][2]),
    .north_dout_r_i(ver_ns_r[2][2]),
    .east_dout_o   (hor_ew[3][2]),
    .east_dout_v_o (hor_ew_v[3][2]),
    .east_dout_r_i (hor_ew_r[3][2]),
    .south_dout_o  (wire_dout[2]),
    .south_dout_v_o(wire_dout_v[2]),
    .south_dout_r_i(wire_dout_r[2]),
    .west_dout_o   (hor_we[3][1]),
    .west_dout_v_o (hor_we_v[3][1]),
    .west_dout_r_i (hor_we_r[3][1]),
    .conf_en_i     (conf_en[2][2]),
    .conf_en_o     ()
  );

  processing_element_NESW #(
    .DATA_WIDTH    (DATA_WIDTH),
    .CONFIG_BORDER (CONFIG_BORDER),
    .HAS_ADDSUB    (1),
    .HAS_MUL       (1),
    .HAS_SHIFT     (1),
    .HAS_LOGICAL   (1),
    .HAS_CMP       (1),
    .HAS_MUX       (1),
    .DEEP_BUFFER_PE(0),
    .DEEP_BUFFER_FU(0),
    .EAGER_FORK    (0)
  ) PE_15 (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .clr_i         (clr_i),
    .north_din_i   (ver_sn[2][3]),
    .north_din_v_i (ver_sn_v[2][3]),
    .north_din_r_o (ver_sn_r[2][3]),
    .east_din_i    (lat_east[2]),
    .east_din_v_i  (lat_east_v[2]),
    .east_din_r_o  (lat_east_r[2]),
    .south_din_i   ('0),
    .south_din_v_i (1'b0),
    .south_din_r_o (),
    .west_din_i    (hor_ew[3][2]),
    .west_din_v_i  (hor_ew_v[3][2]),
    .west_din_r_o  (hor_ew_r[3][2]),
    .north_dout_o  (ver_ns[2][3]),
    .north_dout_v_o(ver_ns_v[2][3]),
    .north_dout_r_i(ver_ns_r[2][3]),
    .east_dout_o   (),
    .east_dout_v_o (),
    .east_dout_r_i (1'b0),
    .south_dout_o  (wire_dout[3]),
    .south_dout_v_o(wire_dout_v[3]),
    .south_dout_r_i(wire_dout_r[3]),
    .west_dout_o   (hor_we[3][2]),
    .west_dout_v_o (hor_we_v[3][2]),
    .west_dout_r_i (hor_we_r[3][2]),
    .conf_en_i     (conf_en[2][3]),
    .conf_en_o     ()
  );

endmodule
