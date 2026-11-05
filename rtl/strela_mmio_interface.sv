// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela_mmio_interface
  import strela_pkg::*;
  import xheep_reg_pkg::*;
  import xheep_obi_pkg::*;
(
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,

  // MMIO interface
  input  xheep_reg_req_t reg_req_i,
  output xheep_reg_rsp_t reg_rsp_o,

  // Control signals
  output logic start_o,
  output logic clr_o,
  output logic conf_change_o,
  output logic intr_en_o,

  // Status signals
  input logic exec_done_i,
  input logic conf_done_i,

  // Performance counters stimuli
  input main_fsm_t                   state_i,
  input xheep_obi_req_t [NUM_SE-1:0] masters_req_i,
  input xheep_obi_rsp_t [NUM_SE-1:0] masters_resp_i,

  // Input Stream Engines
  output logic [31:0] conf_addr_o,
  output logic [31:0] ise_addr_o  [NUM_ISE],
  output logic [15:0] ise_size_o  [NUM_ISE],
  output logic [15:0] ise_stride_o[NUM_ISE],
  output logic [ 2:0] ise_sew_o   [NUM_ISE],

  // Output Stream Engines
  output logic [31:0] ose_addr_o  [NUM_OSE],
  output logic [15:0] ose_size_o  [NUM_OSE],
  output logic [15:0] ose_stride_o[NUM_OSE],
  output logic [ 2:0] ose_sew_o   [NUM_OSE]
);

  import strela_reg_pkg::*;

  logic [NUM_SE-1:0] stalls;
  logic clr_param;

  strela_reg2hw_t reg2hw;
  strela_hw2reg_t hw2reg;

  strela_reg_top #(
    .reg_req_t(xheep_reg_req_t),
    .reg_rsp_t(xheep_reg_rsp_t)
  ) strela_reg_top_i (
    .clk_i,
    .rst_ni,
    .reg_req_i,
    .reg_rsp_o,
    .hw2reg,
    .reg2hw,
    .devmode_i(1'b1)
  );

  // Control signals
  assign start_o = reg2hw.ctrl.start.q;
  assign clr_o = reg2hw.ctrl.clr.q;
  assign conf_change_o = reg2hw.ctrl.clr_conf.q;

  assign hw2reg.ctrl.start.de = reg2hw.ctrl.start.q;
  assign hw2reg.ctrl.start.d = 1'b0;
  assign hw2reg.ctrl.clr.de = reg2hw.ctrl.clr.q;
  assign hw2reg.ctrl.clr.d = 1'b0;
  assign hw2reg.ctrl.clr_param.de = reg2hw.ctrl.clr_param.q;
  assign hw2reg.ctrl.clr_param.d = 1'b0;
  assign hw2reg.ctrl.clr_conf.de = reg2hw.ctrl.clr_conf.q;
  assign hw2reg.ctrl.clr_conf.d = 1'b0;
  assign hw2reg.ctrl.clr_perf_ctr.de = reg2hw.ctrl.clr_perf_ctr.q;
  assign hw2reg.ctrl.clr_perf_ctr.d = 1'b0;

  // Mode signals
  assign intr_en_o = reg2hw.mode.intr_en.q;

  assign hw2reg.mode.intr_en.de = reg2hw.ctrl.clr.q;
  assign hw2reg.mode.intr_en.d = 1'b0;
  assign hw2reg.mode.perf_ctr_en.de = reg2hw.ctrl.clr.q;
  assign hw2reg.mode.perf_ctr_en.d = 1'b0;

  // Status signals
  assign hw2reg.status.exec_done.de =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_param.q || reg2hw.ctrl.start.q || exec_done_i;
  assign hw2reg.status.exec_done.d =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_param.q || reg2hw.ctrl.start.q ? 1'b0 : exec_done_i;
  assign hw2reg.status.conf_done.de = reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_conf.q || conf_done_i;
  assign hw2reg.status.conf_done.d = reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_conf.q ? 1'b0 : 1'b1;

  // Performance counters
  assign hw2reg.perf_ctr_total_cycles.de =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q || reg2hw.mode.perf_ctr_en.q;
  assign hw2reg.perf_ctr_total_cycles.d =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ? '0 : reg2hw.perf_ctr_total_cycles.q + 1;
  assign hw2reg.perf_ctr_conf_cycles.de =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ||
    (reg2hw.mode.perf_ctr_en.q && state_i == S_MAIN_WAIT);
  assign hw2reg.perf_ctr_conf_cycles.d =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ? '0 : reg2hw.perf_ctr_conf_cycles.q + 1;
  assign hw2reg.perf_ctr_exec_cycles.de =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ||
    (reg2hw.mode.perf_ctr_en.q && state_i == S_MAIN_EXEC);
  assign hw2reg.perf_ctr_exec_cycles.d =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ? '0 : reg2hw.perf_ctr_exec_cycles.q + 1;
  assign hw2reg.perf_ctr_stall_cycles.de =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q || (reg2hw.mode.perf_ctr_en.q && |stalls);
  assign hw2reg.perf_ctr_stall_cycles.d =
    reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_perf_ctr.q ? '0 : reg2hw.perf_ctr_stall_cycles.q + 1;

  for (genvar i = 0; i < NUM_SE; i++) begin : gen_stalls
    assign stalls[i] = masters_req_i[i].req ? !masters_resp_i[i].gnt : 1'b0;
  end

  // Stream engine parameters. CLR and CLR_PARAM set the sizes, strides and
  // addresses to zero and the element widths back to 32 bits.
  assign clr_param = reg2hw.ctrl.clr.q || reg2hw.ctrl.clr_param.q;

  assign conf_addr_o = reg2hw.conf_addr.q;
  assign hw2reg.conf_addr.de = clr_param;
  assign hw2reg.conf_addr.d = '0;

  assign ise_sew_o[0] = reg2hw.ise_sew.ise_0_sew.q;
  assign ise_sew_o[1] = reg2hw.ise_sew.ise_1_sew.q;
  assign ise_sew_o[2] = reg2hw.ise_sew.ise_2_sew.q;
  assign ise_sew_o[3] = reg2hw.ise_sew.ise_3_sew.q;
  assign hw2reg.ise_sew.ise_0_sew.de = clr_param;
  assign hw2reg.ise_sew.ise_0_sew.d = SEW_32;
  assign hw2reg.ise_sew.ise_1_sew.de = clr_param;
  assign hw2reg.ise_sew.ise_1_sew.d = SEW_32;
  assign hw2reg.ise_sew.ise_2_sew.de = clr_param;
  assign hw2reg.ise_sew.ise_2_sew.d = SEW_32;
  assign hw2reg.ise_sew.ise_3_sew.de = clr_param;
  assign hw2reg.ise_sew.ise_3_sew.d = SEW_32;

  assign ose_sew_o[0] = reg2hw.ose_sew.ose_0_sew.q;
  assign ose_sew_o[1] = reg2hw.ose_sew.ose_1_sew.q;
  assign ose_sew_o[2] = reg2hw.ose_sew.ose_2_sew.q;
  assign ose_sew_o[3] = reg2hw.ose_sew.ose_3_sew.q;
  assign hw2reg.ose_sew.ose_0_sew.de = clr_param;
  assign hw2reg.ose_sew.ose_0_sew.d = SEW_32;
  assign hw2reg.ose_sew.ose_1_sew.de = clr_param;
  assign hw2reg.ose_sew.ose_1_sew.d = SEW_32;
  assign hw2reg.ose_sew.ose_2_sew.de = clr_param;
  assign hw2reg.ose_sew.ose_2_sew.d = SEW_32;
  assign hw2reg.ose_sew.ose_3_sew.de = clr_param;
  assign hw2reg.ose_sew.ose_3_sew.d = SEW_32;

  assign ise_addr_o[0] = reg2hw.ise_0_addr.q;
  assign ise_size_o[0] = reg2hw.ise_0_param.ise_0_size.q;
  assign ise_stride_o[0] = reg2hw.ise_0_param.ise_0_stride.q;
  assign ise_addr_o[1] = reg2hw.ise_1_addr.q;
  assign ise_size_o[1] = reg2hw.ise_1_param.ise_1_size.q;
  assign ise_stride_o[1] = reg2hw.ise_1_param.ise_1_stride.q;
  assign ise_addr_o[2] = reg2hw.ise_2_addr.q;
  assign ise_size_o[2] = reg2hw.ise_2_param.ise_2_size.q;
  assign ise_stride_o[2] = reg2hw.ise_2_param.ise_2_stride.q;
  assign ise_addr_o[3] = reg2hw.ise_3_addr.q;
  assign ise_size_o[3] = reg2hw.ise_3_param.ise_3_size.q;
  assign ise_stride_o[3] = reg2hw.ise_3_param.ise_3_stride.q;

  assign hw2reg.ise_0_addr.de = clr_param;
  assign hw2reg.ise_0_addr.d = '0;
  assign hw2reg.ise_0_param.ise_0_size.de = clr_param;
  assign hw2reg.ise_0_param.ise_0_size.d = '0;
  assign hw2reg.ise_0_param.ise_0_stride.de = clr_param;
  assign hw2reg.ise_0_param.ise_0_stride.d = '0;
  assign hw2reg.ise_1_addr.de = clr_param;
  assign hw2reg.ise_1_addr.d = '0;
  assign hw2reg.ise_1_param.ise_1_size.de = clr_param;
  assign hw2reg.ise_1_param.ise_1_size.d = '0;
  assign hw2reg.ise_1_param.ise_1_stride.de = clr_param;
  assign hw2reg.ise_1_param.ise_1_stride.d = '0;
  assign hw2reg.ise_2_addr.de = clr_param;
  assign hw2reg.ise_2_addr.d = '0;
  assign hw2reg.ise_2_param.ise_2_size.de = clr_param;
  assign hw2reg.ise_2_param.ise_2_size.d = '0;
  assign hw2reg.ise_2_param.ise_2_stride.de = clr_param;
  assign hw2reg.ise_2_param.ise_2_stride.d = '0;
  assign hw2reg.ise_3_addr.de = clr_param;
  assign hw2reg.ise_3_addr.d = '0;
  assign hw2reg.ise_3_param.ise_3_size.de = clr_param;
  assign hw2reg.ise_3_param.ise_3_size.d = '0;
  assign hw2reg.ise_3_param.ise_3_stride.de = clr_param;
  assign hw2reg.ise_3_param.ise_3_stride.d = '0;

  assign ose_addr_o[0] = reg2hw.ose_0_addr.q;
  assign ose_size_o[0] = reg2hw.ose_0_param.ose_0_size.q;
  assign ose_stride_o[0] = reg2hw.ose_0_param.ose_0_stride.q;
  assign ose_addr_o[1] = reg2hw.ose_1_addr.q;
  assign ose_size_o[1] = reg2hw.ose_1_param.ose_1_size.q;
  assign ose_stride_o[1] = reg2hw.ose_1_param.ose_1_stride.q;
  assign ose_addr_o[2] = reg2hw.ose_2_addr.q;
  assign ose_size_o[2] = reg2hw.ose_2_param.ose_2_size.q;
  assign ose_stride_o[2] = reg2hw.ose_2_param.ose_2_stride.q;
  assign ose_addr_o[3] = reg2hw.ose_3_addr.q;
  assign ose_size_o[3] = reg2hw.ose_3_param.ose_3_size.q;
  assign ose_stride_o[3] = reg2hw.ose_3_param.ose_3_stride.q;

  assign hw2reg.ose_0_addr.de = clr_param;
  assign hw2reg.ose_0_addr.d = '0;
  assign hw2reg.ose_0_param.ose_0_size.de = clr_param;
  assign hw2reg.ose_0_param.ose_0_size.d = '0;
  assign hw2reg.ose_0_param.ose_0_stride.de = clr_param;
  assign hw2reg.ose_0_param.ose_0_stride.d = '0;
  assign hw2reg.ose_1_addr.de = clr_param;
  assign hw2reg.ose_1_addr.d = '0;
  assign hw2reg.ose_1_param.ose_1_size.de = clr_param;
  assign hw2reg.ose_1_param.ose_1_size.d = '0;
  assign hw2reg.ose_1_param.ose_1_stride.de = clr_param;
  assign hw2reg.ose_1_param.ose_1_stride.d = '0;
  assign hw2reg.ose_2_addr.de = clr_param;
  assign hw2reg.ose_2_addr.d = '0;
  assign hw2reg.ose_2_param.ose_2_size.de = clr_param;
  assign hw2reg.ose_2_param.ose_2_size.d = '0;
  assign hw2reg.ose_2_param.ose_2_stride.de = clr_param;
  assign hw2reg.ose_2_param.ose_2_stride.d = '0;
  assign hw2reg.ose_3_addr.de = clr_param;
  assign hw2reg.ose_3_addr.d = '0;
  assign hw2reg.ose_3_param.ose_3_size.de = clr_param;
  assign hw2reg.ose_3_param.ose_3_size.d = '0;
  assign hw2reg.ose_3_param.ose_3_stride.de = clr_param;
  assign hw2reg.ose_3_param.ose_3_stride.d = '0;

endmodule
