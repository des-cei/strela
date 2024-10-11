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
  input  logic        clr_i,

  // Control
  input  logic        start_i,
  input  logic        exec_i,
  input  logic        conf_needed_i,

  // Configuration
  input  logic [31:0] conf_addr_i,
  input  logic [31:0] input_addr_i,
  input  logic [15:0] input_size_i,
  input  logic [15:0] input_stride_i,
  
  // OBI memory master port
  output obi_req_t    masters_req_o,
  input  obi_resp_t   masters_resp_i,

  // Done
  output logic        conf_done_o,
  output logic        done_o,

  // Configuration enable to the IDM
  output logic        conf_en_o,

  // Input data to the IDM
  output logic [31:0] dout_o,
  output logic        dout_v_o,
  input  logic        dout_r_i
);
  // synopsys sync_set_reset clr_i

  enum logic [2:0] {
    S_IDLE = 3'b000,
    S_CONF = 3'b001,
    S_WAIT = 3'b010,
    S_MREQ = 3'b011,
    S_DONE = 3'b100
  } state, n_state;

  logic [31:0] base_addr;
  logic [15:0] addr_offset, n_addr_offset;
  logic [15:0] n_conf_addr_offset, n_data_addr_offset;
  logic transaction, change_mode;

  logic [FIFO_PTR_WIDTH-1:0] data_count;
  logic full, empty, re;

  assign base_addr = conf_needed_i ? conf_addr_i : input_addr_i;
  assign n_conf_addr_offset = addr_offset + CONF_STRIDE;
  assign n_data_addr_offset = addr_offset + input_stride_i;
  assign n_addr_offset = conf_needed_i ? n_conf_addr_offset : n_data_addr_offset;
  assign transaction = masters_req_o.req & masters_resp_i.gnt;

  assign masters_req_o.we     = 0;
  assign masters_req_o.be     = 4'b1111;
  assign masters_req_o.addr   = base_addr + {16'h0, addr_offset};
  assign masters_req_o.wdata  = 0;

  // Address calculation
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addr_offset <= '0;
    end else begin
      if (clr_i) begin
        addr_offset <= '0;
      end else begin
        if (change_mode) begin
          addr_offset <= '0;
        end else if (transaction) begin
          addr_offset <= n_addr_offset;
        end
      end
    end
  end

  // FSM register
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= S_IDLE;
    end else begin
      if (clr_i) begin
        state <= S_IDLE;
      end else begin
        state <= n_state;
      end
    end
  end

  always_comb
  begin
    n_state = S_IDLE;
    masters_req_o.req = 0;
    change_mode = 1'b0;
    conf_done_o = 1'b0;

    unique case (state)
      S_IDLE:
      begin
        if (start_i & conf_needed_i) begin
          n_state = S_CONF;
        end else if (exec_i & input_size_i != 0) begin
          n_state = S_MREQ;
        end else begin
          n_state = S_IDLE;
        end        
      end
      S_CONF:
      begin
        if (n_addr_offset >= CONF_SIZE & transaction) begin
          n_state = S_WAIT;
          change_mode = 1'b1;
        end else begin
          n_state = S_CONF;
        end
        masters_req_o.req = data_count < WORST_MEM_LATENCY;
      end
      S_WAIT:
      begin
        if (exec_i & input_size_i != 0) begin
          n_state = S_MREQ;
        end else begin
          n_state = S_WAIT;
        end
        conf_done_o = empty;
      end
      S_MREQ:
      begin
        if (n_addr_offset >= input_size_i & transaction) begin
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

  assign dout_v_o = !empty && exec_i;
  assign conf_en_o = !empty && (state == S_CONF || state == S_WAIT);
  assign re = (!empty && (state == S_CONF || state == S_WAIT)) || (dout_r_i & dout_v_o);
  assign done_o = state == S_DONE;

  fifo_v3 fifo_i
  (
    .clk_i        ( clk_i                 ),
    .rst_ni       ( rst_ni                ),
    .flush_i      ( clr_i                 ),
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
