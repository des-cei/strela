// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module counters
  import cgra_pkg::*;
  import obi_pkg::*;
(
  // Clock and reset
  input  logic  clk_i,
  input  logic  rst_ni,

  // Control
  input main_fsm_t state_i,
  
  // Master ports
  input  obi_req_t  [NODES-1:0] masters_req_i,
  input  obi_resp_t [NODES-1:0] masters_resp_i,

  // Ouput of counters
  output logic [31:0] bs_cycles_o,
  output logic [31:0] exec_cycles_o,
  output logic [31:0] stall_cycles_o
);

  logic [31:0] bs_cycles, exec_cycles, stall_cycles;
  logic [NODES-1:0] requests, grants;

  assign bs_cycles_o = bs_cycles;
  assign exec_cycles_o = exec_cycles;
  assign stall_cycles_o = stall_cycles;

  for(genvar i = 0; i < NODES; i++) begin
    assign requests[i] = masters_req_i[i].req;
    assign grants[i] = masters_resp_i[i].gnt;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      bs_cycles <= '0;
      exec_cycles <= '0;
      stall_cycles <= '0;
    end else begin
      if(state_i == S_MAIN_WAIT) begin
        bs_cycles <= bs_cycles + 1;
      end
      if(state_i == S_MAIN_EXEC) begin
        exec_cycles <= exec_cycles + 1;
      end
      if(|requests & ~|grants) begin
        stall_cycles <= stall_cycles + 1;
      end
    end
  end

endmodule
