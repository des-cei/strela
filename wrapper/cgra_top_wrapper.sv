// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module cgra_top_wrapper
  import cgra_pkg::*;
  import obi_pkg::*;
  import reg_pkg::*;
(
  // Clock and reset
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // Top level clock gating unit enable
  input  logic                  en_i,

  // MMIO interface
  input  reg_req_t              reg_req_i,
  output reg_rsp_t              reg_rsp_o,

  // Master ports
  output obi_req_t  [NODES-1:0] masters_req_o,
  input  obi_resp_t [NODES-1:0] masters_resp_i,

  // Interrupt
  output logic                  intr_o
);

  logic clk_cg;

  cgra_clock_gate clk_gate_logic_i (
    .clk_i     ( clk_i ),
    .test_en_i ( 1'b0 ),
    .en_i      ( en_i ),
    .clk_o     ( clk_cg )
  );

  cgra_top cgra_top_i (
      .clk_i( clk_cg ),
      .rst_ni,
      .reg_req_i,
      .reg_rsp_o,
      .masters_req_o,
      .masters_resp_i,
      .intr_o
  );

endmodule
