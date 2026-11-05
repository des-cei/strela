// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela_input_stream_engine
  import strela_pkg::*;
  import xheep_obi_pkg::*;
(
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Control
  input logic start_i,
  input logic exec_i,
  input logic conf_needed_i,

  // Configuration
  input logic [31:0] conf_addr_i,
  input logic [31:0] ise_addr_i,
  input logic [15:0] ise_size_i,
  input logic [15:0] ise_stride_i,
  input logic [ 2:0] ise_sew_i,

  // OBI memory master port
  output xheep_obi_req_t masters_req_o,
  input  xheep_obi_rsp_t masters_resp_i,

  // Done
  output logic conf_done_o,
  output logic done_o,

  // Configuration enable to the CGRA
  output logic conf_en_o,

  // Input data to the CGRA
  output logic [31:0] dout_o,
  output logic        dout_v_o,
  input  logic        dout_r_i
);
  // synopsys sync_set_reset clr_i

  typedef enum logic [2:0] {
    S_IDLE = 3'b000,
    S_CONF = 3'b001,
    S_WAIT = 3'b010,
    S_MREQ = 3'b011,
    S_DONE = 3'b100
  } ise_fsm_t;

  ise_fsm_t state, n_state;

  logic        dma_start;
  logic        dma_done;
  logic [31:0] dma_addr;
  logic [15:0] dma_size;
  logic [15:0] dma_stride;
  logic [ 2:0] dma_sew;
  logic [31:0] dma_data;
  logic        dma_valid;
  logic        dma_ready;

  // DMA. It fetches this engine's column of the bitstream first (S_CONF) and
  // then streams the data (S_MREQ). Its start is held for the whole state and
  // the state is left on its done pulse, so each state runs one transfer.
  obione #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .SIZE_WIDTH(16),
    .STRD_WIDTH(16),
    .FIFO_DEPTH(SE_FIFO_DEPTH)
  ) dma_i (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .clr_i        (clr_i),
    .start_i      (dma_start),
    .rw_i         (1'b0),
    .done_o       (dma_done),
    .addr_i       (dma_addr),
    .size_i       (dma_size),
    .stride_i     (dma_stride),
    .sew_i        (dma_sew),
    .master_req_o (masters_req_o),
    .master_resp_i(masters_resp_i),
    .data_i       ('0),
    .valid_i      (1'b0),
    .ready_o      (),
    .data_o       (dma_data),
    .byte_en_o    (),
    .valid_o      (dma_valid),
    .ready_i      (dma_ready)
  );

  assign dma_start  = state == S_CONF || state == S_MREQ;
  assign dma_addr   = state == S_CONF ? conf_addr_i : ise_addr_i;
  assign dma_size   = state == S_CONF ? CONF_SIZE : ise_size_i;
  assign dma_stride = state == S_CONF ? CONF_STRIDE : ise_stride_i;
  assign dma_sew    = state == S_CONF ? SEW_32 : ise_sew_i;

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

  // A zero size never starts the DMA: after CLR_PARAM the stride is zero too,
  // which obione does not accept.
  always_comb begin
    n_state = S_IDLE;

    unique case (state)
      S_IDLE: begin
        if (start_i & conf_needed_i) begin
          n_state = S_CONF;
        end else if (exec_i & ise_size_i != 0) begin
          n_state = S_MREQ;
        end else if (exec_i) begin
          n_state = S_DONE;
        end else begin
          n_state = S_IDLE;
        end
      end
      S_CONF: begin
        if (dma_done) begin
          n_state = S_WAIT;
        end else begin
          n_state = S_CONF;
        end
      end
      S_WAIT: begin
        if (exec_i & ise_size_i != 0) begin
          n_state = S_MREQ;
        end else if (exec_i) begin
          n_state = S_DONE;
        end else begin
          n_state = S_WAIT;
        end
      end
      S_MREQ: begin
        if (dma_done) begin
          n_state = S_DONE;
        end else begin
          n_state = S_MREQ;
        end
      end
      S_DONE: begin
        n_state = S_DONE;
      end
      default: n_state = S_IDLE;
    endcase
  end

  // obione only reports done once its FIFO is drained, so the whole column
  // has reached the fabric by the time the engine is in S_WAIT.
  assign conf_done_o = state == S_WAIT;
  assign conf_en_o = dma_valid && state == S_CONF;
  assign done_o = state == S_DONE;

  // Sub-word elements are sign-extended to the fabric's 32-bit data path. The
  // width is the DMA's, not the register's: the configuration words share
  // this path, and they are 32-bit whatever width the data stream has.
  always_comb begin
    unique case (dma_sew)
      SEW_8:   dout_o = 32'($signed(dma_data[7:0]));
      SEW_16:  dout_o = 32'($signed(dma_data[15:0]));
      default: dout_o = dma_data;
    endcase
  end

  assign dout_v_o  = dma_valid && state == S_MREQ;
  assign dma_ready = state == S_CONF || (state == S_MREQ && dout_r_i);

endmodule
