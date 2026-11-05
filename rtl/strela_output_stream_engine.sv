// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module strela_output_stream_engine
  import strela_pkg::*;
  import xheep_obi_pkg::*;
(
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // OBI memory master port
  output xheep_obi_req_t masters_req_o,
  input  xheep_obi_rsp_t masters_resp_i,

  // Configuration
  input logic [31:0] ose_addr_i,
  input logic [15:0] ose_size_i,
  input logic [15:0] ose_stride_i,
  input logic [ 2:0] ose_sew_i,

  // Control
  input  logic exec_i,
  output logic done_o,

  // Input data from the CGRA
  input  logic [31:0] din_i,
  input  logic        din_v_i,
  output logic        din_r_o
);

  // synopsys sync_set_reset clr_i

  typedef enum logic [1:0] {
    S_IDLE = 2'b00,
    S_MREQ = 2'b01,
    S_DONE = 2'b10
  } ose_fsm_t;

  ose_fsm_t state, n_state;

  logic [15:0] din_offset;
  logic        din_last;

  logic        dma_done;
  logic        dma_ready;
  logic        dma_valid;

  // DMA. Its start is held for the whole of S_MREQ and the state is left on
  // its done pulse, which obione raises once every write has been answered.
  // Sub-word elements are truncated to their low bits and packed by obione.
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
    .start_i      (state == S_MREQ),
    .rw_i         (1'b1),
    .done_o       (dma_done),
    .addr_i       (ose_addr_i),
    .size_i       (ose_size_i),
    .stride_i     (ose_stride_i),
    .sew_i        (ose_sew_i),
    .master_req_o (masters_req_o),
    .master_resp_i(masters_resp_i),
    .data_i       (din_i),
    .valid_i      (dma_valid),
    .ready_o      (dma_ready),
    .data_o       (),
    .byte_en_o    (),
    .valid_o      (),
    .ready_i      (1'b0)
  );

  // Byte offset of the next element taken from the fabric. Once it reaches
  // the size no more elements are accepted, so a kernel that produces more
  // than was programmed stalls instead of pushing writes past the stream.
  assign din_last = din_offset == ose_size_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      state      <= S_IDLE;
      din_offset <= '0;
    end else begin
      if (clr_i) begin
        state      <= S_IDLE;
        din_offset <= '0;
      end else begin
        state <= n_state;
        if (din_v_i & din_r_o) begin
          din_offset <= din_offset + ose_stride_i;
        end
      end
    end
  end

  // A zero size never starts the DMA: after CLR_PARAM the stride is zero too,
  // which obione does not accept.
  always_comb begin
    n_state = S_IDLE;
    done_o  = 0;

    unique case (state)
      S_IDLE: begin
        if (exec_i) begin
          if (ose_size_i == 0) begin
            n_state = S_DONE;
          end else begin
            n_state = S_MREQ;
          end
        end else begin
          n_state = S_IDLE;
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
        done_o  = 1;
      end
      default: n_state = S_IDLE;
    endcase
  end

  assign din_r_o   = state == S_MREQ && dma_ready && !din_last;
  assign dma_valid = state == S_MREQ && din_v_i && !din_last;

endmodule
