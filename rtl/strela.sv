// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela
  import strela_pkg::*;
  import xheep_obi_pkg::*;
  import xheep_reg_pkg::*;
(
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,

  // MMIO interface
  input  xheep_reg_req_t reg_req_i,
  output xheep_reg_rsp_t reg_rsp_o,

  // Master ports
  output xheep_obi_req_t [NUM_SE-1:0] masters_req_o,
  input  xheep_obi_rsp_t [NUM_SE-1:0] masters_resp_i,

  // Interrupt
  output logic intr_o
);

  logic start, exec, clr, clr_se, clr_cgra, intr, intr_en;
  logic [31:0] conf_addr;
  logic [31:0] ise_addr[NUM_ISE];
  logic [15:0] ise_size[NUM_ISE];
  logic [15:0] ise_stride[NUM_ISE];
  logic [2:0] ise_sew[NUM_ISE];
  logic [31:0] ose_addr[NUM_OSE];
  logic [15:0] ose_size[NUM_OSE];
  logic [15:0] ose_stride[NUM_OSE];
  logic [2:0] ose_sew[NUM_OSE];

  logic conf_needed, conf_change;
  logic [NUM_ISE-1:0] conf_done;
  logic [NUM_SE-1:0] se_done;

  logic [32*NUM_ISE-1:0] din;
  logic [NUM_ISE-1:0] din_v, din_r;
  logic [32*NUM_OSE-1:0] dout;
  logic [NUM_OSE-1:0] dout_v, dout_r;
  logic [3:0] conf_en;

  genvar i;
  main_fsm_t state;

  // MMIO control registers
  strela_mmio_interface mmio_interface_i (
    .clk_i,
    .rst_ni,
    .reg_rsp_o,
    .reg_req_i,
    .masters_resp_i,
    .masters_req_i(masters_req_o),
    .start_o      (start),
    .clr_o        (clr),
    .conf_change_o(conf_change),
    .intr_en_o    (intr_en),
    .conf_done_i  (&conf_done),
    .exec_done_i  (&se_done),
    .state_i      (state),
    .conf_addr_o  (conf_addr),
    .ise_addr_o   (ise_addr),
    .ise_size_o   (ise_size),
    .ise_stride_o (ise_stride),
    .ise_sew_o    (ise_sew),
    .ose_addr_o   (ose_addr),
    .ose_size_o   (ose_size),
    .ose_stride_o (ose_stride),
    .ose_sew_o    (ose_sew)
  );

  // Control unit
  strela_control_unit control_unit_i (
    .clk_i,
    .rst_ni,
    .clr_i        (clr),
    .start_i      (start),
    .conf_change_i(conf_change),
    .conf_done_i  (&conf_done),
    .se_done_i    (&se_done),
    .clr_se_o     (clr_se),
    .clr_cgra_o   (clr_cgra),
    .conf_needed_o(conf_needed),
    .exec_o       (exec),
    .intr_o       (intr),
    .state_o      (state)
  );

  assign intr_o = intr && intr_en;

  // Input Stream Engines
  generate
    for (i = 0; i < NUM_ISE; i++) begin : gen_ise
      strela_input_stream_engine input_stream_engine_i (
        .clk_i,
        .rst_ni,
        .clr_i         (clr || clr_se),
        .masters_resp_i(masters_resp_i[i]),
        .masters_req_o (masters_req_o[i]),
        .start_i       (start),
        .exec_i        (exec),
        .conf_needed_i (conf_needed),
        .conf_addr_i   (conf_addr + CONF_OFFSET[i]),
        .ise_addr_i    (ise_addr[i]),
        .ise_size_i    (ise_size[i]),
        .ise_stride_i  (ise_stride[i]),
        .ise_sew_i     (ise_sew[i]),
        .conf_done_o   (conf_done[i]),
        .done_o        (se_done[i]),
        .conf_en_o     (conf_en[i]),
        .dout_o        (din[32*(i+1)-1:32*i]),
        .dout_v_o      (din_v[i]),
        .dout_r_i      (din_r[i])
      );
    end
  endgenerate

  // Output Stream Engines
  generate
    for (i = 0; i < NUM_OSE; i++) begin : gen_ose
      strela_output_stream_engine output_stream_engine_i (
        .clk_i,
        .rst_ni,
        .clr_i         (clr || clr_se),
        .masters_resp_i(masters_resp_i[NUM_ISE+i]),
        .masters_req_o (masters_req_o[NUM_ISE+i]),
        .ose_addr_i    (ose_addr[i]),
        .ose_size_i    (ose_size[i]),
        .ose_stride_i  (ose_stride[i]),
        .ose_sew_i     (ose_sew[i]),
        .exec_i        (exec),
        .done_o        (se_done[NUM_ISE+i]),
        .din_i         (dout[32*(i+1)-1:32*i]),
        .din_v_i       (dout_v[i]),
        .din_r_o       (dout_r[i])
      );
    end
  endgenerate

  // CGRA
  strela_cgra cgra_i (
    .clk_i,
    .rst_ni,
    .clr_i    (clr || clr_cgra),
    .din_i    (din),
    .din_v_i  (din_v),
    .din_r_o  (din_r),
    .dout_o   (dout),
    .dout_v_o (dout_v),
    .dout_r_i (dout_r),
    .conf_en_i(conf_en)
  );

endmodule
