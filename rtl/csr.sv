// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module csr
  import cgra_pkg::*;
  import reg_pkg::*;
(
  // Clock and reset
  input  logic        clk_i,
  input  logic        rst_ni,

  // MMIO interface
  input  reg_req_t    reg_req_i,
  output reg_rsp_t    reg_rsp_o,

  // Control signals
  output logic        start_o,
  output logic        clr_conf_o,

  // Status signals
  input logic         exec_done_i,
  input logic         conf_done_i,

  // Performance counters
  input  logic [31:0] perf_ctr_total_cycles_i,
  input  logic [31:0] perf_ctr_conf_cycles_i,
  input  logic [31:0] perf_ctr_exec_cycles_i,
  input  logic [31:0] perf_ctr_stall_cycles_i,

  // Input Memory Nodes
  output logic [31:0] conf_addr_o,
  output logic [15:0] conf_size_o,
  output logic [31:0] imn_addr_o    [ INPUT_NODES-1:0],
  output logic [15:0] imn_size_o    [ INPUT_NODES-1:0],
  output logic [15:0] imn_stride_o  [ INPUT_NODES-1:0],

  // Output Memory Nodes
  output logic [31:0] omn_addr_o    [OUTPUT_NODES-1:0],
  output logic [15:0] omn_size_o    [OUTPUT_NODES-1:0]
);

  import strela_reg_pkg::*;

  strela_reg2hw_t reg2hw;
  strela_hw2reg_t hw2reg;

  strela_reg_top #(
    .reg_req_t(reg_req_t),
    .reg_rsp_t(reg_rsp_t)
  ) strela_reg_top_i (
    .clk_i,
    .rst_ni,
    .reg_req_i,
    .reg_rsp_o,
    .hw2reg,
    .reg2hw,
    .devmode_i ( 1'b1 )
  );

  // Control signals
  assign start_o = reg2hw.ctrl.start.q;
  assign clr_conf_o = reg2hw.ctrl.clr_conf.q;
  
  // Reset some control signals
  assign hw2reg.ctrl.start.de = reg2hw.ctrl.start.q;
  assign hw2reg.ctrl.start.d  = 1'b0;
  assign hw2reg.ctrl.clr_param.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.ctrl.clr_param.d  = 1'b0;
  assign hw2reg.ctrl.clr_conf.de = reg2hw.ctrl.clr_conf.q;
  assign hw2reg.ctrl.clr_conf.d  = 1'b0;
  assign hw2reg.ctrl.perf_ctr_en.de = 1'b0;
  assign hw2reg.ctrl.perf_ctr_en.d  = 1'b0;
  assign hw2reg.ctrl.perf_ctr_rst.de = reg2hw.ctrl.perf_ctr_rst.q;
  assign hw2reg.ctrl.perf_ctr_rst.d  = 1'b0;

  // Status signals
  assign hw2reg.status.exec_done.de = exec_done_i || reg2hw.ctrl.clr_param.q || reg2hw.ctrl.start.q;
  assign hw2reg.status.exec_done.d  = reg2hw.ctrl.clr_param.q || reg2hw.ctrl.start.q ? 1'b0 : 1'b1;
  assign hw2reg.status.conf_done.de = conf_done_i || reg2hw.ctrl.clr_conf.q;
  assign hw2reg.status.conf_done.d  = reg2hw.ctrl.clr_conf.q ? 1'b0 : 1'b1;

  // Performance counters
  assign hw2reg.perf_ctr_total_cycles.de = 1'b1;
  assign hw2reg.perf_ctr_total_cycles.d  = perf_ctr_total_cycles_i;
  assign hw2reg.perf_ctr_conf_cycles.de = 1'b1;
  assign hw2reg.perf_ctr_conf_cycles.d  = perf_ctr_conf_cycles_i;
  assign hw2reg.perf_ctr_exec_cycles.de = 1'b1;
  assign hw2reg.perf_ctr_exec_cycles.d  = perf_ctr_exec_cycles_i;
  assign hw2reg.perf_ctr_stall_cycles.de = 1'b1;
  assign hw2reg.perf_ctr_stall_cycles.d  = perf_ctr_stall_cycles_i;

  // Input Memory Nodes
  assign conf_addr_o = reg2hw.conf_addr.q;
  assign conf_size_o = reg2hw.conf_size.q;
  assign imn_addr_o[0]    = reg2hw.imn_0_addr.q;
  assign imn_size_o[0]    = reg2hw.imn_0_param.imn_0_size.q;
  assign imn_stride_o[0]  = reg2hw.imn_0_param.imn_0_stride.q;
  assign imn_addr_o[1]    = reg2hw.imn_1_addr.q;
  assign imn_size_o[1]    = reg2hw.imn_1_param.imn_1_size.q;
  assign imn_stride_o[1]  = reg2hw.imn_1_param.imn_1_stride.q;
  assign imn_addr_o[2]    = reg2hw.imn_2_addr.q;
  assign imn_size_o[2]    = reg2hw.imn_2_param.imn_2_size.q;
  assign imn_stride_o[2]  = reg2hw.imn_2_param.imn_2_stride.q;
  assign imn_addr_o[3]    = reg2hw.imn_3_addr.q;
  assign imn_size_o[3]    = reg2hw.imn_3_param.imn_3_size.q;
  assign imn_stride_o[3]  = reg2hw.imn_3_param.imn_3_stride.q;

  assign hw2reg.conf_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.conf_addr.d  = 1'b0;
  assign hw2reg.conf_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.conf_size.d  = 1'b0;
  assign hw2reg.imn_0_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_addr.d  = 1'b0;
  assign hw2reg.imn_0_param.imn_0_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_param.imn_0_size.d  = 1'b0;
  assign hw2reg.imn_0_param.imn_0_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_param.imn_0_stride.d  = 1'b0;
  assign hw2reg.imn_1_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_addr.d  = 1'b0;
  assign hw2reg.imn_1_param.imn_1_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_param.imn_1_size.d  = 1'b0;
  assign hw2reg.imn_1_param.imn_1_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_param.imn_1_stride.d  = 1'b0;
  assign hw2reg.imn_2_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_addr.d  = 1'b0;
  assign hw2reg.imn_2_param.imn_2_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_param.imn_2_size.d  = 1'b0;
  assign hw2reg.imn_2_param.imn_2_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_param.imn_2_stride.d  = 1'b0;
  assign hw2reg.imn_3_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_addr.d  = 1'b0;
  assign hw2reg.imn_3_param.imn_3_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_param.imn_3_size.d  = 1'b0;
  assign hw2reg.imn_3_param.imn_3_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_param.imn_3_stride.d  = 1'b0;

  // Output Memory Nodes
  assign omn_addr_o[0] = reg2hw.omn_0_addr.q;
  assign omn_size_o[0] = reg2hw.omn_0_size.q;
  assign omn_addr_o[1] = reg2hw.omn_1_addr.q;
  assign omn_size_o[1] = reg2hw.omn_1_size.q;
  assign omn_addr_o[2] = reg2hw.omn_2_addr.q;
  assign omn_size_o[2] = reg2hw.omn_2_size.q;
  assign omn_addr_o[3] = reg2hw.omn_3_addr.q;
  assign omn_size_o[3] = reg2hw.omn_3_size.q;

  assign hw2reg.omn_0_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_0_addr.d  = 1'b0;
  assign hw2reg.omn_0_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_0_size.d  = 1'b0;
  assign hw2reg.omn_1_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_1_addr.d  = 1'b0;
  assign hw2reg.omn_1_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_1_size.d  = 1'b0;
  assign hw2reg.omn_2_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_2_addr.d  = 1'b0;
  assign hw2reg.omn_2_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_2_size.d  = 1'b0;
  assign hw2reg.omn_3_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_3_addr.d  = 1'b0;
  assign hw2reg.omn_3_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_3_size.d  = 1'b0;

endmodule
