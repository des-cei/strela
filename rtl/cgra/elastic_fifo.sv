// Copyright 2026 CEIMM-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// Parametric-depth elastic FIFO, same handshake/enable semantics as
// elastic_buffer (drop-in replacement) but with DEPTH storage slots instead
// of a fixed 2. Used for FU-side buffering (REG_1/REG_2, control-in) where
// extra slack is needed to absorb latency-imbalanced reconvergence without
// stalling upstream producers (see tmp_fifo_exploration.md).
module elastic_fifo #(
  parameter int DATA_WIDTH = 32,
  parameter int DEPTH      = 4
) (
  // Clock and reset
  input logic clk_i,
  input logic rst_ni,
  input logic clr_i,

  // Control
  input logic en_i,

  // Input data
  input  logic [DATA_WIDTH-1:0] din_i,
  input  logic                  din_v_i,
  output logic                  din_r_o,

  // Output data
  output logic [DATA_WIDTH-1:0] dout_o,
  output logic                  dout_v_o,
  input  logic                  dout_r_i
);
  // synopsys sync_set_reset clr_i

  localparam int PtrWidth = $clog2(DEPTH);
  localparam int CntWidth = $clog2(DEPTH + 1);

  logic [DATA_WIDTH-1:0] mem[DEPTH];
  logic [PtrWidth-1:0] wr_ptr, rd_ptr;
  logic [CntWidth-1:0] count;

  logic push, pop;
  assign push = din_v_i && din_r_o;
  assign pop = dout_v_o && dout_r_i;

  assign din_r_o = count != CntWidth'(DEPTH);
  assign dout_v_o = count != CntWidth'(0);
  assign dout_o = mem[rd_ptr];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else if (clr_i) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else if (en_i) begin
      if (push) begin
        mem[wr_ptr] <= din_i;
        wr_ptr <= (wr_ptr == PtrWidth'(DEPTH - 1)) ? '0 : wr_ptr + 1'b1;
      end
      if (pop) begin
        rd_ptr <= (rd_ptr == PtrWidth'(DEPTH - 1)) ? '0 : rd_ptr + 1'b1;
      end
      case ({
        push, pop
      })
        2'b10:   count <= count + 1'b1;
        2'b01:   count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

endmodule
