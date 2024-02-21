// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module config_memory_node
  import cgra_pkg::*;
  import obi_pkg::*;
(
  // Clock and reset
  input  logic        clk_i,
  input  logic        rst_ni,

  // Control
  input  logic        bs_needed_i,
  input  logic        execute_i,
  output logic        bs_done_o,

  // Configuration
  input  logic [31:0] config_addr_i,
  input  logic [15:0] config_size_i,
  
  // OBI memory master port
  output obi_req_t    masters_req_o,
  input  obi_resp_t   masters_resp_i,

  // Configuration of CGRA
  output logic [159:0]  kernel_config_o
);

  enum logic [1:0] {
    S_IDLE = 2'b00,
    S_MREQ = 2'b01,
    S_DONE = 2'b10,
    S_DELAY = 2'b11
  } state, n_state;

  logic [15:0] addr_offset, n_addr_offset;
  logic transaction;

  assign n_addr_offset = addr_offset + 16'h4;
  assign transaction = masters_req_o.req & masters_resp_i.gnt;

  assign masters_req_o.we     = 0;
  assign masters_req_o.be     = 4'b1111;
  assign masters_req_o.addr   = config_addr_i + {16'h0, addr_offset};
  assign masters_req_o.wdata  = 0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      addr_offset <= '0;
      state <= S_IDLE;
    end else begin
      if(transaction) begin
        addr_offset <= n_addr_offset;
      end      
      state <= n_state;
    end
  end

  always_comb
  begin
    n_state = S_IDLE;
    masters_req_o.req = 0;
    bs_done_o = 0;

    unique case (state)
      S_IDLE:
      begin
        if(execute_i & bs_needed_i) begin
          n_state = S_MREQ;
        end else begin
          n_state = S_IDLE;
        end        
      end
      S_MREQ:
      begin
        if(n_addr_offset >= config_size_i & transaction) begin
          n_state = S_DELAY;
        end else begin
          n_state = S_MREQ;
        end
        masters_req_o.req = 1;
      end
      S_DELAY: 
      begin
        n_state = S_DONE;
      end
      S_DONE: 
      begin
        n_state = S_DONE;
        bs_done_o = 1;
      end
      default : n_state = S_IDLE;
    endcase
  end

  deserializer deserializer_i
  (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .enable_i       (masters_resp_i.rvalid),
    .data_i         (masters_resp_i.rdata),
    .kernel_config_o(kernel_config_o)
  );

endmodule
