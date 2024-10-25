// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module mmio_interface
  import strela_pkg::*;
  import reg_pkg::*;
  import obi_pkg::*;
(
  // Clock and reset
  input  logic        clk_i,
  input  logic        rst_ni,

  // MMIO interface
  input  reg_req_t    reg_req_i,
  output reg_rsp_t    reg_rsp_o,

  // Control signals
  output logic        start_o,
  output logic        conf_change_o,

  // Status signals
  input logic         exec_done_i,
  input logic         conf_done_i,

  // Performance counters stimuli
  input main_fsm_t              state_i,
  input  obi_req_t  [NODES-1:0] masters_req_i,
  input  obi_resp_t [NODES-1:0] masters_resp_i,

  // Input Memory Nodes
  output logic [31:0] conf_addr_o,
  output logic [31:0] imn_addr_o    [ INPUT_NODES-1:0],
  output logic [15:0] imn_size_o    [ INPUT_NODES-1:0],
  output logic [15:0] imn_stride_o  [ INPUT_NODES-1:0],

  // Output Memory Nodes
  output logic [31:0] omn_addr_o    [OUTPUT_NODES-1:0],
  output logic [15:0] omn_size_o    [OUTPUT_NODES-1:0]
);

  import strela_reg_pkg::*;

  logic [NODES-1:0] stalls;

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
  assign conf_change_o = reg2hw.ctrl.clr_conf.q;
  
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
  assign hw2reg.perf_ctr_total_cycles.de = reg2hw.ctrl.perf_ctr_rst.q || reg2hw.ctrl.perf_ctr_en.q;
  assign hw2reg.perf_ctr_total_cycles.d  = reg2hw.ctrl.perf_ctr_rst.q ? '0 : reg2hw.perf_ctr_total_cycles.q + 1;
  assign hw2reg.perf_ctr_conf_cycles.de = reg2hw.ctrl.perf_ctr_rst.q || (reg2hw.ctrl.perf_ctr_en.q && state_i == S_MAIN_WAIT);
  assign hw2reg.perf_ctr_conf_cycles.d  = reg2hw.ctrl.perf_ctr_rst.q ? '0 : reg2hw.perf_ctr_conf_cycles.q + 1;
  assign hw2reg.perf_ctr_exec_cycles.de = reg2hw.ctrl.perf_ctr_rst.q || (reg2hw.ctrl.perf_ctr_en.q && state_i == S_MAIN_EXEC);
  assign hw2reg.perf_ctr_exec_cycles.d  = reg2hw.ctrl.perf_ctr_rst.q ? '0 : reg2hw.perf_ctr_exec_cycles.q + 1;
  assign hw2reg.perf_ctr_stall_cycles.de = reg2hw.ctrl.perf_ctr_rst.q || (reg2hw.ctrl.perf_ctr_en.q && |stalls);
  assign hw2reg.perf_ctr_stall_cycles.d  = reg2hw.ctrl.perf_ctr_rst.q ? '0 : reg2hw.perf_ctr_stall_cycles.q + 1;

  for(genvar i = 0; i < NODES; i++) begin
    assign stalls[i] = masters_req_i[i].req ? !masters_resp_i[i].gnt : 1'b0;
  end

  // Input Memory Nodes
  assign conf_addr_o = reg2hw.conf_addr.q;
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
  assign hw2reg.conf_addr.d  = '0;
  assign hw2reg.imn_0_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_addr.d  = '0;
  assign hw2reg.imn_0_param.imn_0_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_param.imn_0_size.d  = '0;
  assign hw2reg.imn_0_param.imn_0_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_0_param.imn_0_stride.d  = '0;
  assign hw2reg.imn_1_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_addr.d  = '0;
  assign hw2reg.imn_1_param.imn_1_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_param.imn_1_size.d  = '0;
  assign hw2reg.imn_1_param.imn_1_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_1_param.imn_1_stride.d  = '0;
  assign hw2reg.imn_2_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_addr.d  = '0;
  assign hw2reg.imn_2_param.imn_2_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_param.imn_2_size.d  = '0;
  assign hw2reg.imn_2_param.imn_2_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_2_param.imn_2_stride.d  = '0;
  assign hw2reg.imn_3_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_addr.d  = '0;
  assign hw2reg.imn_3_param.imn_3_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_param.imn_3_size.d  = '0;
  assign hw2reg.imn_3_param.imn_3_stride.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.imn_3_param.imn_3_stride.d  = '0;

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
  assign hw2reg.omn_0_addr.d  = '0;
  assign hw2reg.omn_0_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_0_size.d  = '0;
  assign hw2reg.omn_1_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_1_addr.d  = '0;
  assign hw2reg.omn_1_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_1_size.d  = '0;
  assign hw2reg.omn_2_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_2_addr.d  = '0;
  assign hw2reg.omn_2_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_2_size.d  = '0;
  assign hw2reg.omn_3_addr.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_3_addr.d  = '0;
  assign hw2reg.omn_3_size.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.omn_3_size.d  = '0;

endmodule
