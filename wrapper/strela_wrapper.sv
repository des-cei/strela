// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela_wrapper
  import strela_pkg::*;
  import xheep_obi_pkg::*;
  import xheep_reg_pkg::*;
(
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,

  // Top level clock gating unit enable
  input logic strela_clk_en_i,

  // MMIO interface
  input  xheep_reg_req_t reg_req_i,
  output xheep_reg_rsp_t reg_rsp_o,

  // Master ports
  output xheep_obi_req_t [NUM_SE-1:0] masters_req_o,
  input  xheep_obi_rsp_t [NUM_SE-1:0] masters_resp_i,

  // Interrupt
  output logic intr_o
);

  logic clk_cg;

  strela_clock_gate clk_gate_logic_i (
    .clk_i    (clk_i),
    .test_en_i(1'b0),
    .en_i     (strela_clk_en_i),
    .clk_o    (clk_cg)
  );

  strela strela_i (
    .clk_i(clk_cg),
    .rst_ni,
    .reg_req_i,
    .reg_rsp_o,
    .masters_req_o,
    .masters_resp_i,
    .intr_o
  );

endmodule
