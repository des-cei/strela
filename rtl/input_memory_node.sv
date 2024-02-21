// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module input_memory_node
  import cgra_pkg::*;
  import obi_pkg::*;
(
  // Clock and reset
  input  logic        clk_i,
  input  logic        rst_ni,

  // Control
  input  logic        execute_i,

  // Configuration
  input  logic [31:0] input_addr_i,
  input  logic [15:0] input_size_i,
  input  logic [15:0] input_stride_i,
  
  // OBI memory master port
  output obi_req_t    masters_req_o,
  input  obi_resp_t   masters_resp_i,

  // Input data to the IDM
  output logic [31:0] dout_o,
  output logic        dout_v_o,
  input  logic        dout_r_i
);

  enum logic [1:0] {
    S_IDLE = 2'b00,
    S_MREQ = 2'b01,
    S_DONE = 2'b10
  } state, n_state;

  logic [15:0] addr_offset, n_addr_offset;
  logic transaction;

  logic [FIFO_PTR_WIDTH-1:0] data_count;
  logic full, empty, re;

  assign n_addr_offset = addr_offset + input_stride_i;
  assign transaction = masters_req_o.req & masters_resp_i.gnt;

  assign masters_req_o.we     = 0;
  assign masters_req_o.be     = 4'b1111;
  assign masters_req_o.addr   = input_addr_i + {16'h0, addr_offset};
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

    unique case (state)
      S_IDLE:
      begin
        if(execute_i & input_size_i != 0) begin
          n_state = S_MREQ;
        end else begin
          n_state = S_IDLE;
        end        
      end
      S_MREQ:
      begin
        if(n_addr_offset >= input_size_i & transaction) begin
          n_state = S_DONE;
        end else begin
          n_state = S_MREQ;
        end
        masters_req_o.req = data_count < WORST_MEM_LATENCY;
      end
      S_DONE: 
      begin
        n_state = S_DONE;
      end
      default : n_state = S_IDLE;
    endcase
  end

  assign dout_v_o = !empty;
  assign re = dout_r_i & dout_v_o;

  fifo_v3 fifo_i
  (
    .clk_i        ( clk_i                 ),
    .rst_ni       ( rst_ni                ),
    .flush_i      ( 1'b0                  ),
    .testmode_i   ( 1'b0                  ),
    .usage_o      ( data_count            ),
    .data_i       ( masters_resp_i.rdata  ),
    .push_i       ( masters_resp_i.rvalid ),
    .full_o       ( full                  ),
    .data_o       ( dout_o                ),
    .pop_i        ( re                    ),
    .empty_o      ( empty                 )
  );

endmodule
